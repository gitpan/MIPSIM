package MIPSIM::BasicEmulator::Config;
use MIPSIM::Config '-base';

sub default_config {
    return {
        main_class => 'MIPSIM',
        memory_class => 'MIPSIM::Memory',
	alu_class => 'MIPSIM::ALU',
	emulator_class => 'MIPSIM::BasicEmulator',
        config_class => 'MIPSIM::BasicEmulator::Config',
        hub_class => 'MIPSIM::Hub',
        command_class => 'MIPSIM::BasicEmulator::Command',
        instruction_class => 'MIPSIM::Instruction',
        register_class => 'MIPSIM::Register',
        stack_class => 'MIPSIM::Stack',
    };
}

1;
