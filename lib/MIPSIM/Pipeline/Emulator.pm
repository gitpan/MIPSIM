package MIPSIM::Pipeline::Emulator;
use strict;
use MIPSIM '-Base';

our $VERSION = '0.01';

const class_id => 'emulator';
const config_class => 'MIPSIM::Pipeline::Config';
const command_class => 'MIPSIM::Pipeline::Command';
field verbose => 1;

1;
