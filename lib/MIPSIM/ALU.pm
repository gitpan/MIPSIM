package MIPSIM::ALU;

=head1 NAME

MIPSIM::ALU - ALU Unit in the Emulator

=cut

use strict;
use MIPSIM '-Base';

const class_id => 'alu';
field foo => {};

field using => 0;

sub op {
    my ($op,$a,$b) = @_;
    if($op eq 'ADD') {
	$self->using(2);
	return $a + $b;
    }
    elsif($op eq 'SUB') {
	$self->using(2);
	return $a - $b;
    }
    elsif($op eq 'MUL') {
	$self->using(3);
	return $a * $b;
    }
    elsif($op eq 'DIV') {
	die "Divide-by-zero" if $b == 0;
	$self->using(5);
	return $a / $b;
    }
}

1;

=head1 COPYRIGHT

Copyright 2004 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut
