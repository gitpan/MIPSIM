package MIPSIM::Memory;

=head1 NAME

MIPSIM::Memory -- Memory Storage

=cut

use strict;
use MIPSIM '-Base';

const class_id => 'memory';

# Data memory, hashref, value in size of 'word'.
field dmem => {};

=head2 mem($addr,$value)

Access the value of memory with given address.
If $value not given, then return the current value
in Mem[$addr]. If it's given, then store $value into it.

=cut

sub mem {
    my ($addr,$value) = @_;

    die "Invalid memory address\n"
	unless($addr =~ /^\d+/);

    my $dmem = $self->dmem;

    # save the value
    if(defined($value)) {
	return $dmem->{$addr} = $value;
    }
    # fetch the value
    return $dmem->{$addr};
}

=head2 dump

Dump currently stored values.

=cut

sub dump {
    my $mem = $self->dmem;
    for(keys %$mem){
	print "$_ : $mem->{$_}\n";
    }
}

1;

=head1 COPYRIGHT

Copyright by gugod@gugod.org.

=cut
