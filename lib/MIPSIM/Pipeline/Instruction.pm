package MIPSIM::Pipeline::Instruction;
use strict;
use MIPSIM::Instruction '-Base';
use YAML;
use Perl6::Form;

our $VERSION = '0.01';

=head1 NAME

MIPSIM::PipelineInstruction - Pipelined Instruction processing

=head1 DESCRIPTION

=cut

const class_id => 'instruction';

# Program counter
field pc => 0;

# Stalled on n-th stage.
field stall_stage => 0;

field clock => 0;

# $table->{$n}->{IF} = $clock
field otable => {};

=head2 run($io)

Assume $io is an IO::All object that present lines of code. And
execute all lines in it.

=cut


field gcounter => 0;

sub run {
    my $io = shift;
    my @lines = $self->neat($io);

    # Store codes in to $self->code,
    $self->code(\@lines);
    $self->check_label;

    # IF is responsible to fetch the pc-th line in ->code,
    # and fill the IFID pipeline reg.
    #
    # The other stages are responsible to do whatever they should
    # do using it's left pipeline register as input.

    my $clock = 0;
    my $notend = 1;
    while($notend) {
	$notend = 0;
	if($self->alu->using > 0) {
	    my $u = $self->alu->using;
	    $u--;
	    $self->alu->using($u);
	    $notend = 1;
	} else {
	    $notend |= $self->WB;
	    $notend |= $self->MEM;
	    $notend |= $self->EX;
	    $notend |= $self->ID;
	    $notend |= $self->IF;
	}
	$self->register->sync;
	$clock++;
	$self->clock($clock);
#	$self->dump;
    }
    $self->dumpO;

}

sub dump {
    local $\ = "\n";
    no warnings;
    print STDERR "IFID: " . $self->register->OIFID->{IR} || '';
    print STDERR "IDEX: " . $self->register->OIDEX->{IR} || '';
    print STDERR "EXMEM: " . $self->register->OEXMEM->{IR} || '';
    print STDERR "MEMWB: " . $self->register->OMEMWB->{IR} || '';
    print STDERR "Stalled on " . $self->stall_stage || '0';
    print STDERR "-----";
}

sub IF {
    my $code = $self->code;


    if ($self->stall_stage > 1) {
#	print STDERR "IF: Stalled on " . $self->stall_stage . "\n";
	return 1;
    }

    {
	my $s = $self->register->OIFID;
	$self->stall_stage(0);
	if($s->{IR}) {
	    if($self->isBranch($s->{OP})) {
		$self->register->NIFID({});
		$self->stall_stage(1);
		return 1;
	    }
	}

	$s = $self->register->OIDEX;
	if($s->{IR}) {
	    if($self->isBranch($s->{OP})) {
		$self->register->NIFID({});
		$self->stall_stage(1);
	    }
	}
    }

    return 1 if ($self->stall_stage == 1);

    unless(defined $code->[$self->pc]) {
	$self->register->NIFID({});
	return 0;
    }

    my $r = {
        IR  => $code->[$self->pc],
	NPC => $self->pc + 1,
    };
    $self->pc($r->{NPC});

    my $gcounter = $self->gcounter;
    $gcounter += 1;
    $self->gcounter($gcounter);
    $r->{gcounter} = "$gcounter:$r->{IR}";
#    $r->{gcounter} = $gcounter;

    my $table = $self->otable;
    $table->{$r->{gcounter}}->{IF} = $self->clock;
    $self->otable($table);


# Check Branch
    my $s = $self->register->OEXMEM;
    if($s->{IR}) {
	if($self->isBranch($s->{OP}) && $s->{Cond}) {
#	    print STDERR "BRANCH!!";
	    $r = {};
	    $self->pc($s->{ALUOutput});
	}
    }




    $self->register->NIFID($r);

    1;
}

sub data_hazard_detect {
    # Detect Data Hazard here
    my $r = $self->register->OIFID;
    $self->stall_stage(0);
    for my $pr qw(OIDEX OEXMEM OMEMWB) {
	my $s =  $self->register->$pr;
	if( $s->{IR} ) {
	    if(($r->{RT} eq $s->{RD}) ||
		   ($r->{RS} eq $s->{RD}) ||
		       ($s->{RD} eq $r->{RD}))
		{
		    $self->stall_stage(2);
		    last;
		}
	}
    }
    return $self->stall_stage;
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

    $self->data_hazard_detect;

    # Stalled on me, clean the next pipeline register.
    $self->register->NIDEX({}) if $self->stall_stage == 2;
    return 1 if $self->stall_stage >= 2;
#    YYY($r);

    $r->{ReadMem} = 0;


    $r->{V_RT} = $self->register->$rs
	if($self->register->can($rt));
    $r->{V_RS} = $self->register->$rs
	if($self->register->can($rs));
    $r->{V_RD} = $self->register->$rd;

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

    my $table = $self->otable;
    $table->{$r->{gcounter}}->{ID} = $self->clock;
    $self->otable($table);

    1;
}

sub EX {
    my $r = $self->register->OIDEX;
    unless($r->{IR}) {
	$self->register->NEXMEM({});
	return 0 ;
    }

    my $table = $self->otable;
    $table->{$r->{gcounter}}->{EX} = $self->clock;
    $self->otable($table);

    if($self->stall_stage >= 3) {
	return 1;
    }

    my $op = $r->{OP};
    if($self->isALU($op)) {
	$r->{ALUOutput} = $self->alu->op($op,$r->{A},$r->{B}||$r->{IMM});
    } elsif($self->isLDSD($op)) {
	if($r->{ReadMem}) {
#	    $r->{ALUOutput} = $r->{A} + $r->{IMM};
	    $r->{ALUOutput} = $self->alu->op('ADD',$r->{A},$r->{IMM});
	} else {
#	    $r->{ALUOutput} = $r->{IMM};
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
    $table->{$r->{gcounter}}->{MEM} = $self->clock;
    $self->otable($table);

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

sub WB {
    my $r = $self->register->OMEMWB;
    return 0 unless $r->{IR};

    my $table = $self->otable;
    $table->{$r->{gcounter}}->{WB} = $self->clock;
    $self->otable($table);

    return 1 if $self->stall_stage >= 5;
    my $op = $r->{OP};
    my $rd = $r->{RD};
    my $rt = $r->{RT};
    if($self->isALU($op)) {
	my $val = $r->{ALUOutput};
	$self->register->$rd($val);
    } elsif ($self->isLDSD($op)) {
	if($op =~ /^LD/) {
	    $self->register->$rd($r->{LMD});
	}
    }

    1;
}

sub dumpO {
    my $t = $self->otable;
    no warnings;
    print form
        " =======================================================================",
        "| Instruction # |    IF    |    ID    |    EX    |    MEM    |    WB    |",
        "|---------------+----------+----------+----------+-----------+----------|";
    print form
	"| {<<<<<<<<<<<} | {||||||} | {||||||} | {||||||} | {|||||||} | {||||||} |",
	$_,
	    $t->{$_}->{"IF"},
		$t->{$_}->{"ID"} ||'',
		    $t->{$_}->{"EX"} ||'',
			$t->{$_}->{"MEM"} ||'',
			    $t->{$_}->{"WB"} ||''
	for sort {$a <=> $b} keys %$t;

    print form 
        " -----------------------------------------------------------------------";
}

1;

