package MIPSIM::Pipeline::Instruction::Scoreboard;
use strict;
use MIPSIM::Pipeline::Instruction '-Base';
use YAML;

our $VERSION = '0.01';

=head1 NAME

MIPSIM::Pipeline::Instruction::Scoreboard - Pipelined Instruction processing

=head1 DESCRIPTION

=cut

const class_id => 'instruction';


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
1;

