package MIPSIM::Pipeline::Config;
use MIPSIM::Config '-base';

sub default_config {
    return {
        main_class => 'MIPSIM',
        memory_class => 'MIPSIM::Memory',
	alu_class => 'MIPSIM::ALU',
	emulator_class => 'MIPSIM::Pipeline::Emulator',
        config_class => 'MIPSIM::Pipeline::Config',
        hub_class => 'MIPSIM::Hub',
        command_class => 'MIPSIM::Pipeline::Command',
        instruction_class => 'MIPSIM::Pipeline::Instruction',
        register_class => 'MIPSIM::Pipeline::Register',
        stack_class => 'MIPSIM::Stack',
    };
}

1;
