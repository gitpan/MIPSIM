package MIPSIM::Stack;
use strict;
use MIPSIM '-base';

our $VERSION = '0.01';

=head1 MIPSIM::Stack

This package is the main stack maintaines class
in the simulator.

=cut

field const class_id => 'stack';

sub new {
    my $class = shift;
    my $self = {};
    bless($self,$class);
    my ($pargs,@fargs) = $self->parse_arguments(@_);
    return $self;
}

1;
