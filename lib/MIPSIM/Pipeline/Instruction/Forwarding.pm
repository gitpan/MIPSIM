package MIPSIM::Pipeline::Instruction::Forwarding;
use strict;
use MIPSIM::Pipeline::Instruction '-Base';
use YAML;
use Perl6::Form;

our $VERSION = '0.02';

=head1 NAME

MIPSIM::Pipeline::Instruction::Forwarding - Pipelined Instruction processing

=head1 DESCRIPTION

=cut

const class_id => 'instruction';

field fwdexrs => 0;
field fwdexrt => 0;
field fwdmemrs => 0;
field fwdmemrt => 0;

sub reset_fwd {
    $self->fwdexrs(0);
    $self->fwdexrt(0);
    $self->fwdmemrs(0);
    $self->fwdmemrt(0);
}

sub hazard_detect {
    # Detect Data Hazard here
    my $p2 = $self->register->OIDEX;
    my $p3 = $self->register->OEXMEM;
    my $p4 = $self->register->OMEMWB;

    $self->reset_fwd;

    if($p4->{IR} && $p2->{IR}) {
	unless($self->isBranch($p4->{OP})) {
	    $self->fwdexrs(4) if $p4->{RD} eq $p2->{RS};
	    $self->fwdexrt(4) if $p4->{RD} eq $p2->{RT};
	}
    }

    if($p3->{IR} && $p2->{IR}) {
#	if($self->isALU($p3->{OP})) {
	unless($self->isBranch($p3->{OP})) {
	    $self->fwdexrs(3) if $p3->{RD} eq $p2->{RS};
	    $self->fwdexrt(3) if $p3->{RD} eq $p2->{RT};
	}
    }

    if($p4->{IR} && $p3->{IR}) {
	unless($self->isBranch($p4->{OP})) {
	    $self->fwdmemrs(4) if $p4->{RD} eq $p3->{RS};
	    $self->fwdmemrt(4) if $p4->{RD} eq $p3->{RT};
	}
    }
}

sub data_hazard_detect {
    # Detect Data Hazard here
    my $r = $self->register->OIFID;
    my $s =  $self->register->OIDEX;
    $self->stall_stage(0);
    if( $s->{IR} && $r->{IR} ) {
	my ($op,$rd,$rs,$rt) = $self->parse($r->{IR});
	if($self->isBranch($s->{OP})) {
	    $self->stall_stage(2);
	}
	if($s->{RD} eq $rd) { # WAW
	    $self->stall_stage(2);
	}
	if($self->isLDSD($s->{OP}) && $s->{RD} eq $rs) {
	    $self->stall_stage(2);
	}
	if($self->isLDSD($s->{OP}) && $s->{RD} eq $rt) {
	    $self->stall_stage(2);
	}
    }
    return $self->stall_stage;
}

sub dump {
    super;
    for my $i (0..31) {
	my $r = "R$i";
	my $v = $self->register->$r;
	unless($v == 0) {
	    print "!! $r: $v\n";
	}
   }
}

sub EX {
    my $r = $self->register->OIDEX;
    unless($r->{IR}) {
	$self->register->NEXMEM({});
	return 0 ;
    }

    $self->register->NEXMEM({}) if $self->stall_stage == 3;
    return 1 if $self->stall_stage >= 3;

    my $op = $r->{OP};
    my $rs = $r->{RS};
    my $rt = $r->{RT};

    # Check Forwarding.
    my $s = $self->register->OEXMEM;
    my $t = $self->register->OMEMWB;
    my $a = $r->{A};
    my $b = $r->{B};
    $b = $r->{IMM} unless(defined($b));

    if($self->fwdexrs == 3) {
	$a = $s->{ALUOutput};
    } elsif($self->fwdexrs == 4) {
	$a = $t->{ALUOutput};
    }
    if($self->fwdexrt == 3 ) {
	$b = $s->{ALUOutput};
    } elsif($self->fwdexrt == 4 ) {
	$b = $t->{ALUOutput};
    }

    if($self->isALU($op)) {
	$r->{ALUOutput} = $self->alu->op($op,$a,$b);
    } elsif($self->isLDSD($op)) {
	if($r->{ReadMem}) {
	    $r->{ALUOutput} = $self->alu->op('ADD',$r->{A},$r->{IMM});
	} else {
	    $r->{ALUOutput} = $self->alu->op('ADD',0,$r->{IMM});
	}
    } elsif($self->isBranch($op)) {
	my $bop = "V_$op";
	my $val = $self->$bop($r->{V_RD},$r->{V_RS},$r->{RT});

	if($val) {
	    $r->{ALUOutput} = $val;
	    $r->{Cond}      = 1;
	}
    }

    my $table = $self->otable;
    $table->{$r->{gcounter}}->{EX} = $self->clock
	unless(defined $table->{$r->{gcounter}}->{EX});

    $self->otable($table);

    $self->register->NEXMEM($r);
    1;
}

sub MEM {
    my $r = $self->register->OEXMEM;
    unless($r->{IR}) {
	$self->register->NMEMWB({});
	return 0;
    }

    my $table = $self->otable;
    $table->{$r->{gcounter}}->{MEM} = $self->clock
	unless(defined $table->{$r->{gcounter}}->{MEM});
    $self->otable($table);

    $self->register->NMEMWB({}) if $self->stall_stage == 4;
    return 1 if $self->stall_stage >= 4;

    my $op = $r->{OP};
    if($self->isALU($op)) {
    } elsif ($self->isLDSD($op)) {
	if($op =~ /^LD/) {
	    if($r->{ReadMem}) {
		$r->{LMD} = $self->memory->mem($r->{ALUOutput});
	    } else {
		$r->{LMD} = $r->{ALUOutput};
	    }
	} else {
	    $self->memory->mem($r->{ALUOutput}, $r->{B});
	}
    }

    $self->register->NMEMWB($r);
    1;
}

sub ID {
    my $r = $self->register->OIFID;
    unless($r->{IR}) {
	$self->register->NIDEX({});
	return 0;
    }
    my $line = $r->{IR};

    my ($op,$rd,$rs,$rt) = $self->parse($line);

    $r->{OP} = $op;
    $r->{RD} = $rd;
    $r->{RS} = $rs;
    $r->{RT} = $rt;

    my $table = $self->otable;
    $table->{$r->{gcounter}}->{ID} = $self->clock
	unless(defined $table->{$r->{gcounter}}->{ID});
    $self->otable($table);

    # Stalled on me, clean the next pipeline register.
    $self->register->NIDEX({}) if $self->stall_stage == 2;
    return 1 if $self->stall_stage >= 2;

    $r->{ReadMem} = 0;
    $r->{V_RT} = $self->register->$rs
	if($self->register->can($rt));
    $r->{V_RS} = $self->register->$rs
	if($self->register->can($rs));
    $r->{V_RD} = $self->register->$rd;

    my $mem = $self->register->OMEMWB;
    if($rs =~ /(\d*)\((R\d+)\)/) {
	# Must be LD/SD or the same kind.
	$r->{A}   = $self->register->$2;
	$r->{B}   = $r->{V_RD};
	$r->{IMM} = $1||0;
	$r->{ReadMem} = 1;
    } elsif ($rs =~ /#(\d+)/) {
	# LDI or the same kind
	$r->{A}   = $r->{V_RD};
	$r->{IMM} = $1;
	$r->{V_RS} = $1;
    } elsif ($rt =~ /#(\d+)/) {
	# Must be ADDI or the same kind.
	$r->{A}   = $r->{V_RS};
	$r->{IMM} = $1;
	$r->{V_RT} = $1;
    } else {
	# Like the R-type here.
	$r->{A}   = $r->{V_RS};
	$r->{B}   = $r->{V_RT};
    }

    $self->register->NIDEX($r);

    1;
}

sub run {
    my $io = shift;
    my @lines = $self->neat($io);

    # Store codes in to $self->code,
    $self->code(\@lines);
    $self->check_label;

    my $clock = 0;
    my $noend = 1;
    while($noend) {
	$noend = 0;
	$self->data_hazard_detect;
	$self->hazard_detect;
	if($self->alu->using > 0) {
	    my $u = $self->alu->using;
	    $u--;
	    $self->alu->using($u);
	    $noend = 1;
	    $noend |= $self->WB;
	    $self->register->NMEMWB({});
	} else {
	    $noend |= $self->WB;
	    $noend |= $self->MEM;
	    $noend |= $self->EX;
	    $noend |= $self->ID;
	    $noend |= $self->IF;
	}

	$self->register->sync;
	$clock++;
	$self->clock($clock);
#	$self->dumpO;
    }
    $self->dumpO;
}


1;

