use Module::Build;
use strict;
use warnings;

my $build = Module::Build->new(
	module_name => 'Games::Maze',

	dist_abstract => 'Create Mazes',
	dist_author => 'John M. Gamble <jgamble@cpan.org>',
	dist_version => '1.05',
	dist_name => 'Games-Maze',

	requires => { perl=> '5.8.3' },
	configure_requires => { 'Module::Build' => '0.3624'},
	build_requires => { 'Test::Simple' => 0 },

	license => 'perl',
	create_readme => 0,
	create_makefile_pl => 'traditional',

	meta_merge => {
		keywords => [qw(games maze mazes)],

		resourses => {
			repository => 'git://github.com/jgamble/Games-Maze.git',
#			repository => {
#				url => 'git://github.com/jgamble/Games-Maze.git',
#				web => 'https://github.com/jgamble/Games-Maze',
#				type => 'git',
		},
	},
);

$build->create_build_script;
