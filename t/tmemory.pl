#!/usr/bin/perl -w
# Author: gugod@ib.gugod.org
# Purpose:

use strict;
use Test::Simple tests => 102;
use MIPSIM::BasicEmulator;

my $m = MIPSIM::BasicEmulator->new->load_hub->load_class('memory');

$m->mem(0,100);
my $v = $m->mem(0);
ok(100 == $v);
for(0..100) {
    my $k = int(rand(65535));
    my $v = int(rand(65535));
    $m->mem($k,$v);
    ok($v == $m->mem($k));
}
