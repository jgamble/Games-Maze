use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'		=> 'Games::Maze',
    'VERSION_FROM'	=> 'Maze.pm',
    'ABSTRACT_FROM'	=> 'Maze.pm',	# Get the one-liner from pod.
    'AUTHOR'		=> 'John M. Gamble (jgamble@ripco.com)',
    'HTMLLIBPODS'	=> 'Maze.pm',
);
