package MIPSIM::Command;
use strict;
use MIPSIM '-Base';

field const class_id => 'command';

field args => {};

sub paired_arguments { qw(-file) }

sub process {
    my $args = $self->parse_arguments(@_);
    $self->args($args);
    return $self->run if $args->{-file};
    return $self->usage;
}

sub run {
    my $args = $self->args;
    $self->use_class('instruction');
    $self->use_class('register');

    $self->instruction->run(io($args->{-file}));
    $self->register->dump;
}

sub usage {
    print <<USAGE;

    mipsim-basic -file <input>

USAGE
}

1;
