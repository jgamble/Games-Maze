# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; };
END {print "not ok 1\n" unless $loaded;}
use Games::Maze;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):


my $minos = Games::Maze->new();
$minos->make();
my $theseus = $minos->new();
my $xd_minos = $minos->to_hex_dump();
my $xd_theseus = $theseus->to_hex_dump();

print "not " unless ($xd_minos eq $xd_theseus);
print "ok 2\n";

$minos = Games::Maze->new(cell => 'hex', form => 'hexagon');
$minos->make();
$theseus = $minos->new();
$xd_minos = $minos->to_hex_dump();
$xd_theseus = $theseus->to_hex_dump();

print "not " unless ($xd_minos eq $xd_theseus);
print "ok 3\n";
