package MIPSIM::BasicEmulator;
use strict;
use MIPSIM '-Base';

our $VERSION = '0.01';

const class_id => 'emulator';
const config_class => 'MIPSIM::BasicEmulator::Config';
const command_class => 'MIPSIM::BasicEmulator::Command';
field verbose => 1;

1;
