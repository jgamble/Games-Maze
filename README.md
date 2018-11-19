# Games::Maze version 1.08

Create Mazes as Objects.

```perl
use Games::Maze;

my $m1 = Games::Maze->new(dimensions => [12,7,3]);
my $m2 = Games::Maze->new(dimensions => [8,5,2], cell => 'Hex');

$m1->make();

print scalar($m1->to_ascii());

$m1->solve();

print "\n\nThe Solution:\n\n", scalar($m1->to_ascii());
```

# INSTALLATION

The usual way.  Unpack the archive:
	gzip -d Games-Maze-1.08.tar.gz
	tar xvf  Games-Maze-1.08.tar

```sh
perl Build.PL
./Build
./Build test
./Build install
```

# COPYRIGHT AND LICENSE

Copyright (c) 2012 John M. Gamble.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

