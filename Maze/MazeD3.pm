package MazeD3;

$VERSION = '0.01';
require 5.003_20;	# Same version the 'constant' package requires.
use integer;
use strict;
use Carp;
use vars qw($VERSION);

#
# Our Directions.
#
#     North = 0
#             ^   5 = Down
#             |
#  West = 1<--.-->4 = East
#             |
#    Up = 2   v
#             3 = South
#
# North   (row -=1)
# East    (col +=1)
# Ceiling (lvl -=1)
# South   (row +=1)
# West    (col -=1)
# Floor   (lvl +=1)
#
# The maze is represented as a matrix, sized 0..lvls+1, 0..cols+1, 0..rows+1.
# To avoid special "are we at the edge" checks, the outer border
# cells of the matrix are pre-marked, which leaves the cells in the
# area of 1..lvls, 1..cols, 1..rows to generate the maze.
#
# The top level upper left hand cell is the 0,0,0 corner of the cube.  This
# is why they are called "levels" instead of "storeys".
#
use constant North => 0;
use constant West  => 1;
use constant Ceiling => 2;
use constant South => 3;
use constant East  => 4;
use constant Floor => 5;
use constant Directions => 6;

use constant North_Wall   => 1 << North;
use constant West_Wall    => 1 << West;
use constant Ceiling_Wall => 1 << Ceiling;
use constant South_Wall   => 1 << South;
use constant East_Wall    => 1 << East;
use constant Floor_Wall   => 1 << Floor;
use constant All_Walls    => (1 << Directions) - 1;

use constant Wall_Bits => (North_Wall, West_Wall, Ceiling_Wall,
			South_Wall, East_Wall, Floor_Wall);

use constant Path_Mark => 1 << Directions;

my($Debug_make_ascii, $Debug_make_vx) = (0, 0);
my($Debug_solve_ascii, $Debug_solve_vx) = (0, 0);


=head1 NAME

Games::MazeD3 - Create 3-D maze objects.

Maze creation is done through the maze object's methods, listed below:

=cut

=over 4

=item new([columns, [rows, [levels]]])

Creates the object with it's attributes. Columns, rows, and levels will
default to 3, 3, and 2 if you don't pass parameters to the method.

=cut
sub new()
{
	my($class) = shift;
	my($col, $row, $level) = @_;
	my($self) = {};

	$col = 3 unless (defined $col);
	$row = 3 unless (defined $row);
	$level = 1 unless (defined $level);
	croak "Minimum dimensions are 2 by 2 by 1" if ($row < 2 or $col < 2 or $level < 1);

	$self->{'rows'} = $row;
	$self->{'cols'} = $col;
	$self->{'lvls'} = $level;
	$self->{'final_col'} = 0;
	$self->{'start_col'} = 0;
	$self->{'final_row'} = 0;
	$self->{'start_row'} = 0;
	$self->{'final_level'} = 0;
	$self->{'start_level'} = 0;

	$self->{'form'} = 'Cube';
	$self->{'generate'} = 'Random Simply-Connected';
	$self->{'class'} = $class;

	bless $self, $class;

	$self->{'_corn'} = ([]);

	return &reset($self);
}

=item describe

Returns information about the maze object.

=cut
sub describe()
{
	my($self) = shift;

	return $self->{('cols', 'rows', 'lvls', 'form')};
}

=item reset

Resets the matrix m. You should not normally need to call this method,
as the other methods will call it when needed.

=cut
sub reset
{
	my($self) = shift;
	my($m) = $self->{'_corn'};
	my($l, $c, $r);

	#
	# Reset the center cells to unbroken.
	#
	foreach $l (1..$self->{'lvls'})
	{
		foreach $r (1..$self->{'rows'})
		{
			foreach $c (1..$self->{'cols'})
			{
				$$m[$l][$r][$c] = 0;
			}
		}
	}

	#
	# Set the border cells.
	#
	foreach $l (0..$self->{'lvls'} + 1)
	{
		foreach $r (0..$self->{'rows'} + 1)
		{
			$$m[$l][$r][$self->{'cols'} + 1] = All_Walls;
			$$m[$l][$r][0] = All_Walls;
		}
		foreach $c (0..$self->{'cols'} + 1)
		{
			$$m[$l][$self->{'rows'} + 1][$c] = All_Walls;
			$$m[$l][0][$c] = All_Walls;
		}
	}

	foreach $r (1..$self->{'rows'})
	{
		foreach $c (1..$self->{'cols'})
		{
			$$m[$self->{'lvls'} + 1][$r][$c] = All_Walls;
			$$m[0][$r][$c] = All_Walls;
		}
	}

	$self->{'status'} = 'reset';
	return $self;
}

=item make

Perform a random walk through the walls of the grid. This creates a
simply-connected maze.

=cut
sub make
{
	my($self) = shift;
	my($m) = $self->{'_corn'};
	my(@queue, @dir, $wall);

#	my($c, $r, $l) = (1, 1, 1);
	my($c) = int(rand($self->{'cols'})) + 1;
	my($r) = int(rand($self->{'rows'})) + 1;
	my($l) = int(rand($self->{'lvls'})) + 1;

	$self->reset() if ($self->{'status'} ne 'reset');

	for (;;)
	{
		@dir = &_collect_dirs($m, $c, $r, $l);

		#
		# There is a cell to break into.
		#
		if (@dir > 0)
		{
			#
			# If there were multiple choices, save it
			# for future reference.
			#
			push @queue, ($c, $r, $l) if (@dir > 1);

			#
			# Choose a wall at random and break into the next cell.
			#
			$wall = $dir[int(rand(@dir))];
			$$m[$l][$r][$c] |= (Wall_Bits)[$wall];

			($wall, $c, $r, $l) = &_move_thru($wall, $c, $r, $l);

			$$m[$l][$r][$c] |= (Wall_Bits)[$wall];
			warn $self->to_hex_dump() if ($Debug_make_vx);
			warn $self->to_ascii() if ($Debug_make_ascii);
		}
		else	# No place to go, back up.
		{
			last if (@queue == 0);
			$c = shift @queue;
			$r = shift @queue;
			$l = shift @queue;
		}
	}

	&_set_start_final($self);
	$self->{'status'} = 'make';
	return $self;
}

=item solve

Finds a solution to the maze by examining a path until a
dead end is reached.

=cut
sub solve
{
	my($self) = shift;
	my($m) = $self->{'_corn'};
	my($r) = $self->{'start_row'};
	my($c) = $self->{'start_col'};
	my($l) = $self->{'start_level'};
	my($dir) = North;
	my($ll, $cc, $rr);

	$self->make() if ($self->{'status'} ne 'make');

	$$m[$l][$r][$c] |= Path_Mark;

	while ($c != $self->{'final_col'} or $r != $self->{'final_row'} or $l != $self->{'final_level'})
	{
		#
		# Look around for an open wall (bit == 1).
		#
		while (1)
		{
			$dir = ($dir + 1) % Directions;
			last unless (($$m[$l][$r][$c] & (Wall_Bits)[$dir]) == 0)
		}

		#
		# Mark (or unmark) the cell we are about to leave.
		#
		($dir, $cc, $rr, $ll) = &_move_thru($dir, $c, $r, $l);

		if (($$m[$ll][$rr][$cc] & Path_Mark) == Path_Mark)
		{
			$$m[$l][$r][$c] ^= Path_Mark;
		}
		else
		{
			$$m[$ll][$rr][$cc] ^= Path_Mark;
		}

		($c, $r, $l) = ($cc, $rr, $ll);

		warn $self->to_hex_dump() if ($Debug_solve_vx);
		warn $self->to_ascii() if ($Debug_solve_ascii);
	}

	$self->{'status'} = 'solve';
	return $self;
}

=item to_hex_dump

Returns a formatted string all of the cell values, including the border
cells, in hexadecimal.

=cut
sub to_hex_dump
{
	my($self) = shift;
	my($m) = $self->{'_corn'};
	my($l ,$c, $r);
	my($vxstr) = "";

	foreach $l (0..$self->{'lvls'} + 1)
	{
		foreach $r (0..$self->{'rows'} + 1)
		{
			foreach $c (0..$self->{'cols'} + 1)
			{
				$vxstr .= sprintf(" %3x", $$m[$l][$r][$c]);
			}
			$vxstr .= "\n";
		}
		$vxstr .= "\n";
	}

	return $vxstr;
}

=item to_ascii

Translate the maze into a string of ascii 7-bit characters. If called in
an array context, return as a list of levels. Otherwise returned as a
single string, each level separated by a single newline.

=cut
sub to_ascii
{
	my($self) = shift;
	my($m) = $self->{'_corn'};
	my($c, $r, $l);
	my($lvlstr) = "";
	my(@levels) = ();

	my(%horiz_walls) = (
		(0         , ":--"),
		(North_Wall, ":  "),
		(South_Wall, ":  ")
	);

	my(%verti_walls) = (
		(0        ,                                   "|  "),
		(West_Wall,                                   "   "),
		(Path_Mark,                                   "| *"),
		(West_Wall|Path_Mark,                         "  *"),
		(Floor_Wall    ,                              "|f "),
		(West_Wall|Floor_Wall,                        " f "),
		(Path_Mark|Floor_Wall,                        "|f*"),
		(West_Wall|Path_Mark|Floor_Wall,              " f*"),
		(Ceiling_Wall  ,                              "|c "),
		(West_Wall|Ceiling_Wall,                      " c "),
		(Path_Mark|Ceiling_Wall,                      "|c*"),
		(West_Wall|Path_Mark|Ceiling_Wall,            " c*"),
		(Floor_Wall|Ceiling_Wall,                     "|b "),
		(West_Wall|Floor_Wall|Ceiling_Wall,           " b "),
		(Path_Mark|Floor_Wall|Ceiling_Wall,           "|b*"),
		(West_Wall|Path_Mark|Floor_Wall|Ceiling_Wall, " b*")
	);

	my($horiz_end, $verti_end) = (":\n", "|\n");

	foreach $l (1..$self->{'lvls'})
	{
		foreach $r (1..$self->{'rows'})
		{
			foreach $c (1..$self->{'cols'})
			{
				$lvlstr .= $horiz_walls{$$m[$l][$r][$c] & North_Wall};
			}

			$lvlstr .= $horiz_end;

			foreach $c (1..$self->{'cols'})
			{
				my($v) = $$m[$l][$r][$c] & (West_Wall|Path_Mark|Floor_Wall|Ceiling_Wall);
				$lvlstr .= $verti_walls{$v};
			}

			$lvlstr .= $verti_end;
		}

		#
		# End of all rows for this level.  Print the closing South walls.
		#
		if ($l == $self->{'final_level'})
		{
			foreach $c (1..$self->{'cols'})
			{
				$lvlstr .= $horiz_walls{($c == $self->{'final_col'})? South_Wall: 0};
			}
		}
		else
		{
			$lvlstr .= $horiz_walls{0} x $self->{'cols'};
		}

		$lvlstr .= $horiz_end;
		push @levels, $lvlstr;
		$lvlstr = "";
	}

	return wantarray? @levels: join("\n", @levels);
}

#
# _set_start_final
#
# Pick the start and finish points on the maze. This will become a
# user-settable choice in the future.
#
sub _set_start_final
{
	my($self) = shift;
	my($m) = $self->{'_corn'};

	$self->{'start_col'} = int(rand($self->{'cols'})) + 1;
	$self->{'final_col'} = int(rand($self->{'cols'})) + 1;

	$self->{'start_row'} = 1;
	$self->{'final_row'} = $self->{'rows'};

	$self->{'final_level'} = $self->{'lvls'};
	$self->{'start_level'} = 1;

	$$m[$self->{'start_level'}][$self->{'start_row'}][$self->{'start_col'}] |= North_Wall;
	return $self;
}

#
# ($dir, $c, $r, $l) = &_move_thru($dir, $c, $r, $l)
#
# Move from the current cell to the next by going in the direction
# of $dir.  The function will return your new coordinates, and the
# number of the wall you just came through, from the point of view
# of your new position.
#
sub _move_thru
{
	my($dir, $c, $r, $l) = @_;
	my($orth) = ($dir % (Directions/2));

	if ($orth == 0)
	{
		$r += ($dir < South)? -1 : 1;
	}
	elsif ($orth == 1)
	{
		$c += ($dir < South)? -1 : 1;
	}
	else
	{
		$l += ($dir < South)? -1 : 1;
	}

	$dir = ($dir + Directions/2) % Directions;

	($dir, $c, $r, $l);
}

#
# @directions = _collect_dirs($m, $c, $r, $l);
#
# Find all of our possible directions to wander when creating the maze.
# You are only allowed to go into not-yet-broken cells.
#
sub _collect_dirs
{
	my($m, $c, $r, $l) = @_;
	my(@dir) = ();

	#
	# Search for enclosed cells.
	#
	push(@dir, North)    if ($$m[$l][$r - 1][$c] == 0);
	push(@dir, South)    if ($$m[$l][$r + 1][$c] == 0);
	push(@dir, West)     if ($$m[$l][$r][$c - 1] == 0);
	push(@dir, East)     if ($$m[$l][$r][$c + 1] == 0);
	push(@dir, Ceiling)  if ($$m[$l - 1][$r][$c] == 0);
	push(@dir, Floor)    if ($$m[$l + 1][$r][$c] == 0);

	@dir;
}
1;
