package MIPSIM::Pipeline::Command;
use MIPSIM::Command '-Base';

const class_id => 'command';

sub boolean_arguments {qw(-forwarding -tomasulo -scoreboard)}

sub run {
    my $args = $self->args;
    $self->use_class('config');
    my $config = $self->config;

    if($args->{-forwarding}) {
	$config->{instruction_class} = 'MIPSIM::Pipeline::Instruction::Forwarding';
    }elsif($args->{-tomasulo}) {
	$config->{instruction_class} = 'MIPSIM::Pipeline::Instruction::Tomasulo';
    } elsif($args->{-scoreboard}) {
	$config->{instruction_class} = 'MIPSIM::Pipeline::Instruction::Scoreboard';
    }

    $self->config($config);
    $self->use_class('instruction');
    $self->use_class('register');
    $self->instruction->run(io($args->{-file}));
    $self->register->dump;
}


sub usage {
    print <<USAGE;

    mipsim-pipeline [-forwarding|-tomasulo|-scoreboard] -file <input>

USAGE
}


1;
