package MazeXD3;

$VERSION = '0.01';
require 5.003_20;	# Same version the 'constant' package requires.
use integer;
use strict;
use Carp;
use vars qw($VERSION);

#
#                North
#                 (0)
#               ________         (5) Down
#              /        \
# NorthWest   /          \   NorthEast
#     (1)    /     .      \      (6)
#            \            /
# SouthWest   \          /   SouthEast
#     (2)      \________/        (5)
#                South
#  Up (3)         (4)
#
#
# The maze is represented as a matrix, sized 0..lvls+1, 0..cols+1, 0..rows+1.
# To avoid special "are we at the edge" checks, the outer border
# cells of the matrix are pre-marked, which leaves the cells in the
# area of 1..lvls, 1..cols, 1..rows to generate the maze.
#
# The top level upper left hand cell is the 0,0,0 corner of the honeycomb.  This
# is why they are called "levels" instead of "storeys".
#
#
# An 8x4x2 hex grid would look like:
#
# Level 1:
#  __    __    __    __
# /  \__/  \__/  \__/  \__
# \__/  \__/  \__/  \__/  \
# /  \__/  \__/  \__/  \__/
# \__/  \__/  \__/  \__/  \
# /  \__/  \__/  \__/  \__/
# \__/  \__/  \__/  \__/  \
# /  \__/  \__/  \__/  \__/
# \__/  \__/  \__/  \__/  \
#    \__/  \__/  \__/  \__/
#
# Level 2:
#  __    __    __    __
# /  \__/  \__/  \__/  \__
# \__/  \__/  \__/  \__/  \
# /  \__/  \__/  \__/  \__/
# \__/  \__/  \__/  \__/  \
# /  \__/  \__/  \__/  \__/
# \__/  \__/  \__/  \__/  \
# /  \__/  \__/  \__/  \__/
# \__/  \__/  \__/  \__/  \
#    \__/  \__/  \__/  \__/
#

use constant North      => 0;
use constant NorthWest  => 1;
use constant SouthWest  => 2;
use constant Ceiling    => 3;
use constant South      => 4;
use constant SouthEast  => 5;
use constant NorthEast  => 6;
use constant Floor      => 7;
use constant Directions => 8;

use constant North_Wall      => 1 << North;
use constant NorthWest_Wall  => 1 << NorthWest;
use constant SouthWest_Wall  => 1 << SouthWest;
use constant Ceiling_Wall    => 1 << Ceiling;
use constant South_Wall      => 1 << South;
use constant SouthEast_Wall  => 1 << SouthEast;
use constant NorthEast_Wall  => 1 << NorthEast;
use constant Floor_Wall      => 1 << Floor;
use constant All_Walls       => (1 << Directions) - 1;

use constant Wall_Bits => (North_Wall, NorthWest_Wall, SouthWest_Wall, Ceiling_Wall,
			South_Wall, SouthEast_Wall, NorthEast_Wall, Floor_Wall);

use constant Path_Mark => 1 << Directions;

my($Debug_make_ascii, $Debug_make_vx) = (0, 0);
my($Debug_solve_ascii, $Debug_solve_vx) = (0, 0);


=head1 NAME

Games::MazeXD3 - Create 3-D hexagon maze objects.

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

	$self->{'form'} = 'Hexagon-D3';
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
			$$m[$l][$r][0] = All_Walls;
			$$m[$l][$r][$self->{'cols'} + 1] = All_Walls;
		}
		foreach $c (0..$self->{'cols'} + 1)
		{
			$$m[$l][0][$c] = All_Walls ^ (SouthWest_Wall | South_Wall);
			$$m[$l][$self->{'rows'} + 1][$c] = All_Walls ^ NorthWest_Wall;
		}
		$$m[$l][$self->{'rows'} + 1][1] ^= NorthWest_Wall;
	}

	foreach $r (1..$self->{'rows'})
	{
		foreach $c (1..$self->{'cols'})
		{
			$$m[0][$r][$c] = All_Walls;
			$$m[$self->{'lvls'} + 1][$r][$c] = All_Walls;
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

	my(%upper_west) = (
		(0                                                , '/  '),
		(NorthWest_Wall                                   , '   '),
		(Floor_Wall                                       , '/f '),
		(NorthWest_Wall|Floor_Wall                        , ' f '),
		(Ceiling_Wall                                     , '/c '),
		(NorthWest_Wall|Ceiling_Wall                      , ' c '),
		(Floor_Wall|Ceiling_Wall                          , '/b '),
		(NorthWest_Wall|Floor_Wall|Ceiling_Wall           , ' b '),
		(Path_Mark                                        , '/ *'),
		(NorthWest_Wall|Path_Mark                         , '  *'),
		(Floor_Wall|Path_Mark                             , '/f*'),
		(NorthWest_Wall|Floor_Wall|Path_Mark              , ' f*'),
		(Ceiling_Wall|Path_Mark                           , '/c*'),
		(NorthWest_Wall|Ceiling_Wall|Path_Mark            , ' c*'),
		(Floor_Wall|Ceiling_Wall|Path_Mark                , '/b*'),
		(NorthWest_Wall|Floor_Wall|Ceiling_Wall|Path_Mark , ' b*'),
	);
	my(%low_west) = (
		(0                          , '\__'),
		(South_Wall                 , '\  '),
		(SouthWest_Wall             , ' __'),
		(SouthWest_Wall|South_Wall  , '   '),
	);

	foreach $l (1..$self->{'lvls'})
	{
		#
		# Print the top line of the border.
		#
		foreach $c (1..$self->{'cols'})
		{
			if (&_up_column($c) and $c != $self->{'start_col'})
			{
				$lvlstr .= $low_west{(SouthWest_Wall)};
			}
			else
			{
				$lvlstr .= $low_west{SouthWest_Wall|South_Wall};
			}
		}

		$lvlstr .= "\n";

		#
		# Now print the rows.
		#
		foreach $r (1..$self->{'rows'})
		{
			#
			# It takes two lines to print out the hexagon, or parts of the
			# hexagon.  First, the top half.
			#
			foreach $c (1..$self->{'cols'})
			{
				if (&_up_column($c))
				{
					$lvlstr .= $upper_west{$$m[$l][$r][$c] & (NorthWest_Wall|Floor_Wall|Ceiling_Wall|Path_Mark)};
				}
				else
				{
					$lvlstr .= $low_west{$$m[$l][$r - 1][$c] & (SouthWest_Wall|South_Wall)};
				}
			}

			if (&_up_column($self->{'cols'}))
			{
				$lvlstr .= "\\";
			}
			else
			{
				$lvlstr .= "/" unless ($r == 1);
			}
			$lvlstr .= "\n";

			#
			# Now, the lower half.
			#
			foreach $c (1..$self->{'cols'})
			{
				if (&_up_column($c))
				{
					$lvlstr .= $low_west{$$m[$l][$r][$c] & (SouthWest_Wall|South_Wall)};
				}
				else
				{
					$lvlstr .= $upper_west{$$m[$l][$r][$c] & (NorthWest_Wall|Floor_Wall|Ceiling_Wall|Path_Mark)};
				}
			}

			if (&_up_column($self->{'cols'}))
			{
				$lvlstr .= "/";
			}
			else
			{
				$lvlstr .= "\\";
			}
			$lvlstr .= "\n";
		}

		#
		# Print the bottom line of the border.
		#
		foreach $c (1..$self->{'cols'})
		{
			if (&_up_column($c))
			{
				$lvlstr .= $upper_west{$$m[$l][$self->{'rows'} + 1][$c] & (NorthWest_Wall|Path_Mark)};
			}
			else
			{
				$lvlstr .= $low_west{$$m[$l][$self->{'rows'}][$c] & (SouthWest_Wall|South_Wall)};
			}
		}

		$lvlstr .= "/" unless (&_up_column($self->{'cols'}));
		$lvlstr .= "\n";
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

	$self->{'start_level'} = 1;
	$self->{'final_level'} = $self->{'lvls'};

	if (_up_column($self->{'start_col'}))
	{
		$$m[$self->{'start_level'}][$self->{'start_row'}][$self->{'start_col'}] |= North_Wall;
	}
	else
	{
		$$m[$self->{'start_level'}][$self->{'start_row'} - 1][$self->{'start_col'}] |= South_Wall;
	}

	$$m[$self->{'final_level'}][$self->{'final_row'}][$self->{'final_col'}] |= South_Wall;
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

	if ($dir == North)
	{
		$r -= 1;
	}
	elsif ($dir == South)
	{
		$r += 1;
	}
	elsif ($dir == Floor)
	{
		$l += 1;
	}
	elsif ($dir == Ceiling)
	{
		$l -= 1;
	}
	else
	{
		if (&_up_column($c))
		{
			$r -= 1 if ($dir == NorthWest or $dir == NorthEast);
		}
		else
		{
			$r += 1 if ($dir == SouthWest or $dir == SouthEast);
		}

		if ($dir == NorthWest or $dir == SouthWest)
		{
			$c -= 1;
		}
		elsif ($dir == NorthEast or $dir == SouthEast)
		{
			$c += 1;
		}
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
	push(@dir, North) if ($$m[$l][$r - 1][$c] == 0);
	push(@dir, South) if ($$m[$l][$r + 1][$c] == 0);
	push(@dir, Ceiling) if ($$m[$l - 1][$r][$c] == 0);
	push(@dir, Floor) if ($$m[$l + 1][$r][$c] == 0);

	if (&_up_column($c))
	{
		push(@dir, NorthWest) if ($$m[$l][$r - 1][$c - 1] == 0);
		push(@dir, NorthEast) if ($$m[$l][$r - 1][$c + 1] == 0);

		push(@dir, SouthWest) if ($$m[$l][$r][$c - 1] == 0);
		push(@dir, SouthEast) if ($$m[$l][$r][$c + 1] == 0);
	}
	else
	{
		push(@dir, SouthWest) if ($$m[$l][$r + 1][$c - 1] == 0);
		push(@dir, SouthEast) if ($$m[$l][$r + 1][$c + 1] == 0);

		push(@dir, NorthWest) if ($$m[$l][$r][$c - 1] == 0);
		push(@dir, NorthEast) if ($$m[$l][$r][$c + 1] == 0);
	}

	@dir;
}

#
# _up_column($c)
#
# Which columns are higher due to hexagonal drift?
#
sub _up_column
{
	my($c) = @_;
	return $c & 1;
}

1;
