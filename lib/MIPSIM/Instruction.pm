package MIPSIM::Instruction;
use strict;
use MIPSIM '-Base';

our $VERSION = '0.01';

=head1 NAME

MIPSIM::Instruction - Instruction processing

=head1 DESCRIPTION

This class represent an instruction executor, it execute an
instruction and update the registers and stack.

=cut

const class_id => 'instruction';

sub init {
    $self->use_class('config');
    $self->use_class('register');
    $self->use_class('memory');
    $self->use_class('alu');
}

=head2 run($io)

Assume $io is an IO::All object that present lines of code. And
execute all lines in it.

=cut

field pc =>0;
field npc =>0;
field code  => [];
field label => {};

sub run {
    my $io = shift;
    my @lines = $self->neat($io);
    $self->code(\@lines);
    $self->check_label;
    $self->execute;
}

sub check_label {
    my @lines = @{$self->code};
    my $lbl = {};
    for my $i (0..$#lines) {
	if($lines[$i] =~ /^\s*(.+):/ ) {
	    $lbl->{$1} = $i;
	}
    }
    $self->label($lbl);
}

=head2 fetch_value(@str)

Try to fetch the value of given string presentation of addressing
modes.  Return a list of values.

=cut

sub fetch_value {
    my @rv;
    for(@_) {
	if(/^\#(\d+)$/) {
	    # immediate value
	    push @rv, $1;
	} elsif(/^[RF](\d+)$/) {
	    # register
	    die "Don't have such register: $_"
		unless $self->register->can($_);
	    push @rv, $self->register->$_;
	} elsif(/^(\d*)\((R\d+)\)$/) {
	    # memory access
	    die "Don't have such register: $2"
		unless $self->register->can($2);
	    push @rv,$self->memory->mem($1||0 + $self->register->$2);
	} else {
	    # unknown format;
	    die "Don't know what it is: $_"
	}
    }
    return $rv[0] if(scalar(@rv) == 1);
    return @rv;
}


=head2 resolv_mem_address

Calculate memory address from different kind of presentation

=cut


sub resolv_mem_address {
    local $_ = shift;
    if(/^(\d*)\((R\d+)\)$/) {
	return $1||0 + $self->register->$2;
    }
    die "Invalid memory address scheme: $_\n";
}


=head2 neat

Neat the code.

=cut

sub neat {
    my $in = shift;
    # Strip empty lines and whitespaces, Convert to upper-case
    # And merge label-only lines.
    return $self->neat_label(
	map { s/^\s+//; s/\s+$//; $_ }
	map { uc } grep {!/^\s*$/} @{$in});
}

sub neat_label {
    my @lines = @_;
    # Merge the line with only label, into the next line.
    my $dirty = '';
    my @new;
    for (@lines) {
	if(/^\s*(.+):\s*$/) {
	    $dirty = $_;
	} else {
	    if($dirty) {
		push @new, "$dirty $_";
		$dirty = '';
	    } else {
		push @new, $_;
	    }
	}
    }
    return @new;
}

=head2 execute($line)

Execute the instruction in $line.

=cut

sub execute {
    my $code = $self->code;
    my @lines = @{$code};
    my $nlines = scalar(@lines);
    while($self->pc < $nlines ) {
	$self->pc($self->npc);
	$self->npc($self->pc + 1);


	my $line = $lines[$self->pc] || '';
        $line =~ s/\s+$//;
	$line =~ s/^\s+//;
        next if($line =~ /^$/);

        my ($op,$rd,$rs,$rt) = $self->parse($line);
        # Simply skip unknown op
        unless($self->can($op)) {
            warn("I can't do ``$op''"); next;
        }
	$self->check_register($rd);
	if($self->isALU($op)) {
	    my $val = $self->$op($rd,$rs,$rt);
	    $self->register->$rd($val);
	} elsif($self->isLDSD($op)) {
	    my $val = $self->$op($rd,$rs,$rt);
	    $self->register->$rd($val);
	} elsif($self->isBranch($op)) {
	    my $val = $self->$op($rd,$rs,$rt);
	    $self->npc($val) if($val);
	} else {
	    die "Unknown instruction: $line\n";
	}

    };
}


=head2 parse($line)

Parse a $line.

=cut

sub parse {
    my ($line) = @_;
    my ($label) = $line =~s/^(.+):\s*//;
    my ($op,$rest) = split/\s+/,$line,2;
    my ($rd,$rs,$rt) = split/\s*,\s*/,$rest;
    for($rd,$rs,$rt) {
        $_ ||= '';
    }
    # Change FP '.' char to underline
    $op =~ s/\./_/g;
    return ($op,$rd,$rs,$rt);
}

sub execute_dummy {
    my ($me,$line) = @_;
    # The very dummy execution: Just print it
    print "$line\n";
}

# implementation of each instruction

=head2 check_register(@registers)

Check if the argument is a valid register name, or a proper form in
instruction.

=cut

sub check_register {
    my @r = @_;
    for(@r) {
        next unless($_);
        next if(/^#\d+$/);
        die "Don't have such register: $_" unless $self->register->can($_);
    }
}


sub isALU {
    my $op = shift;
    return 1 if $op =~ /^(ADD|SUB|MUL|DIV)/i;
    0;
}

sub isLDSD {
    my $op = shift;
    return 1 if $op =~ /^(LD|SD)/i;
    0;
}

sub isBranch {
    my $op = shift;
    return 1 if $op =~ /^B/i;
    0;
}

=head2 LD

Implement LD. So far $rs can only be immedate value
Example:

    LD R1,#3
    LD R2,#5

=cut

sub LD {
    $self->LDI(@_);
}

=head2 LDI

Implement LDI.
Load Immediate value or memory.

    LDI R1,#3
    LDI R2,#5
    LD R3, 5(R1)

=cut

sub LDI {
    my ($rd,$iv) = @_;
    return $self->register->$rd($self->fetch_value($iv));
}

=head2 LD_D

Implement LD_D.
Load Immediate value or memory.

    LDI F1,#3
    LDI F2,#5
    LD F3, 5(R1)

=cut

sub LD_D {
    my ($rd,$iv) = @_;
    return $self->register->$rd($self->fetch_value($iv));
}


=head2 SD($rd,$addr)

Store Double

=cut

sub SD {
    my ($rd,$addr_str) = @_;
    my ($v) = $self->fetch_value($rd);
    my $addr = $self->resolv_mem_address($addr_str);
    $self->memory->mem($addr,$v);
}

=head2 SD_D($rd,$addr)

Store FP

=cut

sub SD_D {
    my ($rd,$addr_str) = @_;
    my ($v) = $self->fetch_value($rd);
    my $addr = $self->resolv_mem_address($addr_str);
    $self->memory->mem($addr,$v);
}

=head2 ADD

Implement ADD. $rs and $rt can both be immediate or register.
Example:

    LD R3,#1
    ADD R4,R3,#1
    ADD R5,#1,R3

    ADD R6,#2,#3
    ADD R6,#30

=cut

sub ADD {
    use integer;
    my ($rd,$rs,$rt) = @_;
    my ($va,$vb) = $rt ?
	$self->fetch_value($rs,$rt) :
	    $self->fetch_value($rd,$rs);
    my $val = $self->alu->op('ADD',$va,$vb);
    return $val;
}

=head2 ADD_D

Implement ADD_D. $rs and $rt can both be immediate or register.
Example:

    LD F3,#1
    ADD F4,F3,#1
    ADD F5,#1,F3

    ADD F6,#2,#3
    ADD F6,#30

=cut

sub ADD_D {
    my ($rd,$rs,$rt) = @_;
    my ($va,$vb) = $rt ?
	$self->fetch_value($rs,$rt) :
	    $self->fetch_value($rd,$rs);
    return $self->alu->op('ADD',$va,$vb);
}

=head2 SUB

Implement SUB. $rs and $rt can both be immediate or register.

=cut

sub SUB {
    use integer;
    my ($rd,$rs,$rt) = @_;
    my ($va,$vb) = $self->fetch_value($rs,$rt);
    return $self->alu->op('SUB',$va,$vb);
}

=head2 SUB_D

Implement SUB_D. $rs and $rt can both be immediate or register.

=cut

sub SUB_D {
    my ($rd,$rs,$rt) = @_;
    my ($va,$vb) = $self->fetch_value($rs,$rt);
    return $self->alu->op('SUB',$va,$vb);
}


=head2 MUL

Implement MUL. $rs and $rt can both be immediate or register.

=cut

sub MUL {
    use integer;
    my ($rd,$rs,$rt) = @_;
    my ($va,$vb) = $self->fetch_value($rs,$rt);
    return $self->alu->op('MUL',$va,$vb);
}

=head2 MUL_D

Implement MUL_D. $rs and $rt can both be immediate or register.

=cut

sub MUL_D {
    my ($rd,$rs,$rt) = @_;
    my ($va,$vb) = $self->fetch_value($rs,$rt);
    return $self->alu->op('MUL',$va,$vb);
}

=head2 DIV

Implement DIV. $rs and $rt can both be immediate or register.

=cut

sub DIV {
    use integer;
    my ($rd,$rs,$rt) = @_;
    my ($va,$vb) = $self->fetch_value($rs,$rt);
    return $self->alu->op('DIV',$va,$vb);
}

=head2 DIV_D

Implement DIV_D. $rs and $rt can both be immediate or register.

=cut

sub DIV_D {
    my ($rd,$rs,$rt) = @_;
    my ($va,$vb) = $self->fetch_value($rs,$rt);
    return $self->alu->op('DIV',$va,$vb);
}

sub Pos {
    my $L   = shift;
    my $lbl = $self->label;
    die("Unknown label: $L\n") unless(defined $lbl->{$L});
    return $lbl->{$L};
}


=head2 BNE

Implement BNE. $rs should be register, and $rt can both be immediate or register.
$Label should be a Label.

=cut

sub BNE {
    my ($rs,$rt,$Label) = @_;
    my ($va,$vb) = $self->fetch_value($rs,$rt);
    return $self->V_BNE($va,$vb,$Label);
}

=head2 BEQ

Implement BEQ. $rs should be register, and $rt can both be immediate or register.
$Label should be a Label.

=cut

sub BEQ {
    my ($rs,$rt,$Label) = @_;
    my ($va,$vb) = $self->fetch_value($rs,$rt);
    return $self->V_BEQ($va,$vb,$Label);
}

sub V_BEQ {
    my ($va,$vb,$l) = @_;
    return $self->Pos($l) if $va==$vb;
    return 0;
}

sub V_BNE {
    my ($va,$vb,$l) = @_;
    return $self->Pos($l) if $va!=$vb;
    return 0;
}

1;
