package MIPSIM::Pipeline::Instruction::Tomasulo;
use strict;
use MIPSIM::Pipeline::Instruction '-Base';
use YAML;

our $VERSION = '0.01';

=head1 NAME

MIPSIM::Pipeline::Instruction::Tomasulo - Pipelined Instruction processing

=head1 DESCRIPTION

=cut

const class_id => 'instruction';

# FP Instruction Queue/Buffer
field fpIQ => [];

=head2 run($io)

Assume $io is an IO::All object that present lines of code. And
execute all lines in it.

=cut

sub run {
    my $io = shift;
    my @lines = $self->neat($io);

    # Store codes in to $self->code,
    $self->code(\@lines);
    $self->check_label;

    # Re-arrange code with tomasulo here.
    if($) {
    }

    # start runing
    my $clock = 0;
    my $end = 1;
    while($end) {
	$end = 0;

	$end |= $self->WB;
	$end |= $self->MEM;
	$end |= $self->EX;
	$end |= $self->ID;
	$end |= $self->IF;

	$self->register->sync;
	$clock++;
	$self->clock($clock);
#	$self->dump;
    }
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

    if($rs =~ /(\d*)\((R\d+)\)/) {
	# Must be LD/SD or the same kind.
	$r->{A}   = $self->register->$2;
	$r->{B}   = $self->register->$rd;
	$r->{IMM} = $1||0;
	$r->{ReadMem} = 1;
    } elsif ($rs =~ /#(\d+)/) {
	# LDI or the same kind
	$r->{A}   = $self->register->$rd;
	$r->{IMM} = $1;
    } elsif ($rt =~ /#(\d+)/) {
	# Must be ADDI or the same kind.
	$r->{A}   = $self->register->$rs;
	$r->{IMM} = $1;
    } else {
	# Like the R-type here.
	$r->{A}   = $self->register->$rs
	    if($self->register->can($rs));
	$r->{B}   = $self->register->$rt
	    if($self->register->can($rt));
    }
    $self->register->NIDEX($r);
    1;
}



1;

