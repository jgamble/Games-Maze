use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'Games::Maze',
    'VERSION_FROM' => 'Maze/MazeD2.pm', # finds $VERSION
    'MAN3PODS'     => { 'Maze.pod' => './blib/man3/Games::Maze.3' },
    'dist'         => { COMPRESS => 'gzip', SUFFIX => 'gz' }
);
