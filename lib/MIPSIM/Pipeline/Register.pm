package MIPSIM::Pipeline::Register;
use strict;
use MIPSIM::Register '-Base';
use Perl6::Form;

our $VERSION = '0.01';

=head1 MIPSIM::Pipeline::Register

This package maintains all registers and pipeline registers in the simulator.

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

# Pipeline Registers are hashs any field would be ok.

field OIFID  => {};
field OIDEX  => {};
field OEXMEM => {};
field OMEMWB => {};

field NIFID  => {};
field NIDEX  => {};
field NEXMEM => {};
field NMEMWB => {};

=head2 sync

Copy N* to O* register

=cut

sub sync {
    $self->OIFID($self->NIFID);
    $self->OIDEX($self->NIDEX);
    $self->OEXMEM($self->NEXMEM);
    $self->OMEMWB($self->NMEMWB);
}

=head2 dump

=cut

#sub dump {
#    super;
#    print form
#        " =================================================",
#        "| Register | Key        | Value                   |",
#        "|----------+------------+-------------------------|";
#
#    use YAML;
#
#    for my $r qw/IFID IDEX EXMEM MEMWB/ {
#        my $m = "N$r";
#        for my $k (keys %{$self->$m||{}}) {
#
#        my $rv = $self->$m->{$k} || '';
#        $rv = YAML::Dump($rv) if(ref($rv) eq 'HASH');
#
#    print form
#	    "| {<<<<<<} | {<<<<<<<<} | {<<<<<<<<<<<<<<<<<<<<<} |",
#        $r,$k, $rv;
#
#        }
#    }
#
#    print form " =================================================","";
#
#}

1;

