# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; };
END {print "not ok 1\n" unless $loaded;}
use Maze::MazeD2;
use Maze::MazeXD2;
use Maze::MazeD3;
use Maze::MazeXD3;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use Config;

my $restart_seed = 331;
my $rndbits = $Config{'randbits'};
my $human_check = 0;
my @test_files;

if ($rndbits != 15)
{
	warn "I don't have a test case for your perl, which has RANDBITS set to $rndbits\n";
	warn "I'll pass you, but you should look in /tmp to see if you like the output.\n";
	$human_check = 1;
}

srand($restart_seed);
my $r1 = int(rand(1024));
my $r2 = int(rand(1024));
my $r3 = int(rand(1024));

if ($r1 != 91 or $r2 != 992 or $r3 != 588)
{
	warn "Your RANDBITS I recognized, but your rand() function is different.\n";
	warn "I'll pass you, but you should look in /tmp to see if you like the output.\n";
	$human_check = 1;
}

D2:{
	srand($restart_seed);
	my $mfile = "md2.$restart_seed";
	my $minos = MazeD2->new(12, 7);

	open(MFILE, "> /tmp/$mfile") or die "Couldn't open /tmp/$mfile: $!";
	$minos->make();
	print MFILE $minos->to_ascii();
	print MFILE "\n\nSolving...\n\n";
	$minos->solve();
	print MFILE $minos->to_ascii();
	close MFILE;
	push @test_files, "/tmp/" . $mfile;

	unless ($human_check)
	{
		system "diff t/$mfile /tmp/$mfile";

		print "not " if ($? != 0);
	}
	print "ok 2\n" ;
}

XD2:{
	srand($restart_seed);
	my $mfile = "mxd2.$restart_seed";
	my $minos = MazeXD2->new(12, 7);

	open(MFILE, "> /tmp/$mfile") or die "Couldn't open /tmp/$mfile: $!";
	$minos->make();
	print MFILE $minos->to_ascii();
	print MFILE "\n\nSolving...\n\n";
	$minos->solve();
	print MFILE $minos->to_ascii();
	close MFILE;
	push @test_files, "/tmp/" . $mfile;

	unless ($human_check)
	{
		system "diff t/$mfile /tmp/$mfile";

		print "not " if ($? != 0);
	}
	print "ok 3\n" ;
}

D3:{
	srand($restart_seed);
	my $mfile = "md3.$restart_seed";
	my $minos = MazeD3->new(12, 7, 3);

	open(MFILE, "> /tmp/$mfile") or die "Couldn't open /tmp/$mfile: $!";
	$, = "\n\n";

	$minos->make();
	print MFILE $minos->to_ascii();
	print MFILE "\n\nSolving...\n\n";
	$minos->solve();
	print MFILE $minos->to_ascii();
	close MFILE;
	$, = "";
	push @test_files, "/tmp/" . $mfile;

	unless ($human_check)
	{
		system "diff t/$mfile /tmp/$mfile";

		print "not " if ($? != 0);
	}
	print "ok 4\n" ;
}

XD3:{
	srand($restart_seed);
	my $mfile = "mxd3.$restart_seed";
	my $minos = MazeXD3->new(12, 7, 3);

	open(MFILE, "> /tmp/$mfile") or die "Couldn't open /tmp/$mfile: $!";
	$, = "\n\n";
	
	$minos->make();
	print MFILE $minos->to_ascii();
	print MFILE "\n\nSolving...\n\n";
	$minos->solve();
	print MFILE $minos->to_ascii();
	close MFILE;
	$, = "";
	push @test_files, "/tmp/" . $mfile;

	unless ($human_check)
	{
		system "diff t/$mfile /tmp/$mfile";

		print "not " if ($? != 0);
	}
	print "ok 5\n" ;
}

if ($human_check)
{
	warn "Test maze output files are at ", join(" ", @test_files), "\n";
}
else
{
	unlink @test_files;
}
1;
