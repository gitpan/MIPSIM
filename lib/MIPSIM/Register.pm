package MIPSIM::Register;
use strict;
use MIPSIM '-Base';
use Perl6::Form;

our $VERSION = '0.01';

=head1 MIPSIM::Register

This package maintains all registers in the simulator.

=head1 SYNOPSIS

    my $m = MIPSIM::Register->new();

    $m->R1(3)      # set R1 to value 3
    $a = $m->R3    # assign R3's value to $a.

=head1 DESCRIPTION

Please note that, in MIPS aseembly language, register are named as
$1,$2,$3.... . that'd be confusing here in perl. Therefore, we
shall always use R1,R2,R3.... as internal register name. And
it'd be converted from $1 to R1 in Instruction.pm or it's subclass.

=cut

const class_id => 'register';

# R0 is a constant 0, while others are not constant.

const R0 => 0;
field "R$_" => 0 for 1..31;
field "F$_" => 0 for 0..7;

=head2 dump

Dump the content in all registers.

=cut

sub dump {
    print form
        " =================================================",
        "| Register | Value      | Register   | Value      |",
        "|----------+------------+------------+------------|";
    print form
	    "| {<<<<<<} | {<<<<<<<<} | {<<<<<<<<} | {<<<<<<<<} |",
		"R$_",eval"\$self->R$_","R".($_+16),eval"\$self->R".($_+16)
		    for 0..15;
    print form " -------------------------------------------------";
    print form
	    "| {<<<<<<} | {<<<<<<<<} | {<<<<<<<<} | {<<<<<<<<} |",
		"F$_",eval"\$self->F$_","F".($_+4),eval"\$self->F".($_+4)
		    for 0..3;
    print form " =================================================","";
}

1;
