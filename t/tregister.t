#!/usr/bin/perl -w
# Author: gugod@ib.gugod.org
# Purpose:

use strict;
use Test::Simple tests => 63;
use MIPSIM::Register;

my $m = new MIPSIM::Register;
$m->init;

ok( 0 == $m->R0 );

# Test if each "set" to R1 to R31 works
for(1..31) {
    my $R = "R$_";
    $m->$R(1);
    ok( 1 == $m->$R );
}

# Randomly assgign many values to R1 to R31
my $bound = 2**31;
for(1..31) {
    my $R = "R$_";
    my $n = int(rand($bound));
    $m->$R($n);
    ok ( $n = $m->$R );
}
