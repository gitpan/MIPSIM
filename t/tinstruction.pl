#!/usr/bin/perl -w
# Author: gugod@ib.gugod.org
# Purpose:

use strict;
use Test::Simple tests => 69;
use MIPSIM;

my $i = MIPSIM->new->load_hub->load_class('instruction');
my $r = $i->register;

# LD test
for(1..31) {
    my $R = "R$_";
    $i->execute("LD $R,#1");
    $R="R$_";
    ok( 1 == $r->$R );
}

# ADD Immediate
$i->execute('ADD R3,#1,#5');
ok( 6 == $r->R3 );

# ADD register
$i->execute('LD R1,#1' ,
            'LD R2,#1' ,
            'ADD R3,R1,R2'
        );
ok( 2 == $r->R3 );

# ADD register and immediate
$i->execute('LD R3,#1','ADD R4,R3,#1','ADD R5,#1,R3');
ok( 2 == $r->R4 );
ok( 2 == $r->R5 );

# SUB register and immediate
$i->execute('LD R3,#3','SUB R4,R3,#1','SUB R5,#5,R3');
ok( 2 == $r->R4 );
ok( 2 == $r->R5 );

# LDI test
for(1..31) {
    my $R = "R$_";
    $i->execute("LDI $R,#1");
    $R="R$_";
    ok( 1 == $r->$R );
}

# Memory Test
$i->execute('LD R1,#100',
	    'LD R5,#5',
	    'SD R1,(R5)',
	    'LD R2,(R5)'
	   );
ok($r->R1 == $r->R2);

