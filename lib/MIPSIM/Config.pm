package MIPSIM::Config;
use strict;
use Spoon::Config '-base';
use Spoon::Installer '-base';

const class_id => 'config';

sub default_configs {
    my $self = shift;
    my @configs;
    push @configs, "$ENV{HOME}/.mipsim/config.yaml"
      if defined $ENV{HOME} and -f "$ENV{HOME}/.mipsim/config.yaml";
    push @configs, "config.yaml"
      if -f "config.yaml";
    return @configs;
}

sub default_config {
    return {
        main_class => 'MIPSIM',
        memory_class => 'MIPSIM::Memory',
	alu_class => 'MIPSIM::ALU',
	emulator_class => 'MIPSIM::BasicEmulator',
        config_class => 'MIPSIM::Config',
        hub_class => 'MIPSIM::Hub',
        command_class => 'MIPSIM::Command',
        instruction_class => 'MIPSIM::Instruction',
        register_class => 'MIPSIM::Register',
        stack_class => 'MIPSIM::Stack',
    };
}

__DATA__
__config.yaml__

1;
