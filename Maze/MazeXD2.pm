package MazeXD2;

$VERSION = '0.01';
require 5.003_20;	# Same version the 'constant' package requires.
use integer;
use strict;
use Carp;
use vars qw($VERSION);

#
#                North
#                 (0)
#               ________
#              /        \
# NorthWest   /          \   NorthEast
#     (1)    /     .      \      (5)
#            \            /
# SouthWest   \          /   SouthEast
#     (2)      \________/        (4)
#                South
#                 (3)
#
#
# The maze is represented as a matrix, sized 0..cols+1, 0..rows+1.
# To avoid special "are we at the edge" checks, the outer border
# cells of the matrix are pre-marked, which leaves the cells in the
# area of 1..cols, 1..rows to generate the maze.
#
# The upper left hand cell is the 0,0 corner of the grid.
#
#
# An 8x4 hex grid would look like:
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
use constant South      => 3;
use constant SouthEast  => 4;
use constant NorthEast  => 5;
use constant Directions => 6;

use constant North_Wall      => 1 << North;
use constant NorthWest_Wall  => 1 << NorthWest;
use constant SouthWest_Wall  => 1 << SouthWest;
use constant South_Wall      => 1 << South;
use constant SouthEast_Wall  => 1 << SouthEast;
use constant NorthEast_Wall  => 1 << NorthEast;
use constant All_Walls       => (1 << Directions) - 1;

use constant Wall_Bits => (North_Wall, NorthWest_Wall, SouthWest_Wall,
			South_Wall, SouthEast_Wall, NorthEast_Wall);

use constant Path_Mark => 1 << Directions;

my($Debug_make_ascii, $Debug_make_vx) = (0, 0);
my($Debug_solve_ascii, $Debug_solve_vx) = (0, 0);

=head1 NAME

Games::MazeXD2 - Create hexagon maze objects.

Maze creation is done through the maze object's methods, listed below:

=cut

=over 4

=item new([columns, [rows]])

Creates the object with it's attributes. Columns and rows will default
to 3 if you don't pass parameters to the method.

=cut
sub new()
{
	my($class) = shift;
	my($col, $row) = @_;
	my($self) = {};

	$col = 3 unless (defined $col);
	$row = 3 unless (defined $row);
	croak "Minimum dimensions are 2 by 2" if ($row < 2 or $col < 2);

	$self->{'rows'} = $row;
	$self->{'cols'} = $col;
	$self->{'final_col'} = 0;
	$self->{'start_col'} = 0;
	$self->{'final_row'} = 0;
	$self->{'start_row'} = 0;

	$self->{'form'} = 'Hexagon';
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

	return $self->{('cols', 'rows', 'form')};
}

=item reset

Resets the matrix m. You should not normally need to call this method,
as the other methods will call it when needed.

=cut
sub reset
{
	my($self) = shift;
	my($m) = $self->{'_corn'};
	my($c, $r);

	#
	# Reset the center cells to unbroken.
	#
	foreach $r (1..$self->{'rows'})
	{
		$$m[$r][$self->{'cols'} + 1] = All_Walls;
		$$m[$r][0] = All_Walls;

		foreach $c (1..$self->{'cols'})
		{
			$$m[0][$c] = All_Walls ^ (SouthWest_Wall | South_Wall);
			$$m[$self->{'rows'} + 1][$c] = All_Walls ^ NorthWest_Wall;
			$$m[$r][$c] = 0;
		}
	}

	$$m[0][0] = All_Walls;
	$$m[0][$self->{'cols'} + 1] = All_Walls;
	$$m[$self->{'rows'} + 1][$self->{'cols'} + 1] = All_Walls;
	$$m[$self->{'rows'} + 1][0] = All_Walls;

	if (&_up_column(1))
	{
		$$m[0][1] ^= SouthWest_Wall;
		$$m[$self->{'rows'} + 1][1] ^= NorthWest_Wall;
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

#	my($c, $r) = (1, 1);
	my($r) = int(rand($self->{'rows'})) + 1;
	my($c) = int(rand($self->{'cols'})) + 1;

	$self->reset() if ($self->{'status'} ne 'reset');

	for (;;)
	{
		@dir = &_collect_dirs($m, $c, $r);

		#
		# There is a cell to break into.
		#
		if (@dir > 0)
		{
			#
			# If there were multiple choices, save it
			# for future reference.
			#
			push @queue, ($c, $r) if (@dir > 1);

			#
			# Choose a wall at random and break into the next cell.
			#
			$wall = $dir[int(rand(@dir))];
			$$m[$r][$c] |= (Wall_Bits)[$wall];

			($wall, $c, $r) = &_move_thru($wall, $c, $r);

			$$m[$r][$c] |= (Wall_Bits)[$wall];
			warn $self->to_hex_dump() if ($Debug_make_vx);
			warn $self->to_ascii() if ($Debug_make_ascii);
		}
		else	# No place to go, back up.
		{
			last if (@queue == 0);
			$c = shift @queue;
			$r = shift @queue;
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
	my($dir) = North;
	my($cc, $rr);

	$self->make() if ($self->{'status'} ne 'make');

	$$m[$r][$c] |= Path_Mark;

	while ($c != $self->{'final_col'} or $r != $self->{'final_row'})
	{
		#
		# Look around for an open wall (bit == 1).
		#
		while (1)
		{
			$dir = ($dir + 1) % Directions;
			last unless (($$m[$r][$c] & (Wall_Bits)[$dir]) == 0)
		}

		#
		# Mark (or unmark) the cell we are about to leave.
		#
		($dir, $cc, $rr) = &_move_thru($dir, $c, $r);

		if (($$m[$rr][$cc] & Path_Mark) == Path_Mark)
		{
			$$m[$r][$c] ^= Path_Mark;
		}
		else
		{
			$$m[$rr][$cc] ^= Path_Mark;
		}

		($c, $r) = ($cc, $rr);

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
	my($c, $r);
	my($vxstr) = "";

	foreach $r (0..$self->{'rows'} + 1)
	{
		foreach $c (0..$self->{'cols'} + 1)
		{
			$vxstr .= sprintf(" %2x", $$m[$r][$c]);
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
	my($c, $r);
	my($mstr) = "";

	my(%upper_west) = (
		(0                          , '/  '),
		(NorthWest_Wall             , '   '),
		(Path_Mark                  , '/ *'),
		(NorthWest_Wall | Path_Mark , '  *'),
	);
	my(%low_west) = (
		(0                          , '\__'),
		(South_Wall                 , '\  '),
		(SouthWest_Wall             , ' __'),
		(SouthWest_Wall | South_Wall, '   '),
	);

	#
	# Print the top line of the border.
	#
	foreach $c (1..$self->{'cols'})
	{
		if (&_up_column($c) and $c != $self->{'start_col'})
		{
			$mstr .= $low_west{(SouthWest_Wall)};
		}
		else
		{
			$mstr .= $low_west{SouthWest_Wall | South_Wall};
		}
	}

	$mstr .= "\n";

	foreach $r (1..$self->{'rows'})
	{
		#
		# It takes two lines to print out the hexagon, or parts of the
		# hexagon.
		# First, the top half.
		#
		#
		foreach $c (1..$self->{'cols'})
		{
			if (&_up_column($c))
			{
				$mstr .= $upper_west{$$m[$r][$c] & (NorthWest_Wall | Path_Mark)};
			}
			else
			{
				$mstr .= $low_west{$$m[$r - 1][$c] & (SouthWest_Wall | South_Wall)};
			}
		}

		if (&_up_column($self->{'cols'}))
		{
			$mstr .= "\\";
		}
		else
		{
			$mstr .= "/" unless ($r == 1);
		}
		$mstr .= "\n";

		#
		# Now, the lower half.
		#
		foreach $c (1..$self->{'cols'})
		{
			if (&_up_column($c))
			{
				$mstr .= $low_west{$$m[$r][$c] & (SouthWest_Wall | South_Wall)};
			}
			else
			{
				$mstr .= $upper_west{$$m[$r][$c] & (NorthWest_Wall | Path_Mark)};
			}
		}

		if (&_up_column($self->{'cols'}))
		{
			$mstr .= "/";
		}
		else
		{
			$mstr .= "\\";
		}
		$mstr .= "\n";
	}

	#
	# Print the bottom line of the border.
	#
	foreach $c (1..$self->{'cols'})
	{
		if (&_up_column($c))
		{
			$mstr .= $upper_west{$$m[$self->{'rows'} + 1][$c] & (NorthWest_Wall | Path_Mark)};
		}
		else
		{
			$mstr .= $low_west{$$m[$self->{'rows'}][$c] & (SouthWest_Wall | South_Wall)};
		}
	}

	$mstr .= "/" unless (&_up_column($self->{'cols'}));
	$mstr .= "\n";
	return $mstr;
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

	if (_up_column($self->{'start_col'}))
	{
		$$m[$self->{'start_row'}][$self->{'start_col'}] |= North_Wall;
	}
	else
	{
		$$m[$self->{'start_row'} - 1][$self->{'start_col'}] |= South_Wall;
	}

	$$m[$self->{'final_row'}][$self->{'final_col'}] |= South_Wall;
	return $self;
}

#
# ($dir, $c, $r) = &_move_thru($dir, $c, $r)
#
# Move from the current cell to the next by going in the direction
# of $dir.  The function will return your new coordinates, and the
# number of the wall you just came through, from the point of view
# of your new position.
#
sub _move_thru
{
	my($dir, $c, $r) = @_;

	if ($dir == North)
	{
		$r -= 1;
	}
	elsif ($dir == South)
	{
		$r += 1;
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

	($dir, $c, $r);
}

#
# @directions = _collect_dirs($m, $c, $r);
#
# Find all of our possible directions to wander when creating the maze.
# You are only allowed to go into not-yet-broken cells.
#
sub _collect_dirs
{
	my($m, $c, $r) = @_;
	my(@dir) = ();

	#
	# Search for enclosed cells.
	#
	push(@dir, North) if ($$m[$r - 1][$c] == 0);
	push(@dir, South) if ($$m[$r + 1][$c] == 0);

	if (&_up_column($c))
	{
		push(@dir, NorthWest) if ($$m[$r - 1][$c - 1] == 0);
		push(@dir, NorthEast) if ($$m[$r - 1][$c + 1] == 0);

		push(@dir, SouthWest) if ($$m[$r][$c - 1] == 0);
		push(@dir, SouthEast) if ($$m[$r][$c + 1] == 0);
	}
	else
	{
		push(@dir, SouthWest) if ($$m[$r + 1][$c - 1] == 0);
		push(@dir, SouthEast) if ($$m[$r + 1][$c + 1] == 0);

		push(@dir, NorthWest) if ($$m[$r][$c - 1] == 0);
		push(@dir, NorthEast) if ($$m[$r][$c + 1] == 0);
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
