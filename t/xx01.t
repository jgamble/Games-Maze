# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; };
END {print "not ok 1\n" unless $loaded;}
use Games::Maze;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $correct_make = 
q(                                       
                __/  \__                  
             __/  \     \__               
          __/  \     \  /  \__            
       __/  \     \__/  \     \__         
    __/  \     \__/   __/  \  /  \__      
 __/  \     \__/   __/  \  /  \     \__   
/  \     \__/   __/  \     \  /  \  /  \  
\  /  \__/   __/  \     \__/  \  /  \  /  
/  \  /   __/  \     \__/   __/  \  /  \  
\__   \  /  \     \__/   __/  \  /   __/  
   \__/  \     \__/   __/  \     \__/     
      \__   \__/   __/  \     \__/        
         \__/   __/  \     \__/           
            \__   \     \__/              
               \__   \__/                 
                  \  /                    
                                          
                                          
);

my $correct_solve = 
q(                                       
                __/ *\__                  
             __/  \    *\__               
          __/  \     \  / *\__            
       __/  \     \__/ *\    *\__         
    __/  \     \__/ * __/ *\  /  \__      
 __/  \     \__/ * __/ *\  / *\     \__   
/  \     \__/ * __/ *\    *\  /  \  /  \  
\  /  \__/ * __/ *\    *\__/ *\  /  \  /  
/  \  / * __/ *\    *\__/ * __/  \  /  \  
\__   \  / *\    *\__/ * __/  \  /   __/  
   \__/ *\    *\__/ * __/  \     \__/     
      \__  *\__/ * __/  \     \__/        
         \__/ * __/  \     \__/           
            \__  *\     \__/              
               \__  *\__/                 
                  \  /                    
                                          
                                          
);

my $correct_hex =
q( 016b 016b 016b 016b 016b 016b 014b 016b 0143 016b 016b 016b 016b 016b 016b
 016b 016b 016b 016b 014b 014b 0060 8061 8022 0143 0143 016b 016b 016b 016b
 016b 016b 014b 014b 0060 0060 0003 0003 8009 8060 8022 0143 0143 016b 016b
 016b 014b 0060 0060 0003 0003 8108 8108 8060 8021 8021 0060 0022 0143 0163
 016b 0020 0021 0003 8108 8108 8060 8060 8003 8003 8009 0021 0021 0020 0161
 016b 0041 0003 8120 8060 8060 8003 8003 8108 8108 0060 0021 0101 0009 0169
 016b 016b 016b 8041 8003 8003 8108 8108 0060 0060 0003 0003 0169 0169 016b
 016b 016b 016b 016b 016b 8140 8042 0060 0003 0003 0169 0169 016b 016b 016b
 016b 016b 016b 016b 016b 016b 016b 8023 0169 0169 016b 016b 016b 016b 016b
 016b 016b 016b 016b 016b 016b 016b 016b 016b 016b 016b 016b 016b 016b 016b
);

my $minos = Games::Maze->new(
		dimensions => [7, 2, 1], cell => 'hex', form => 'Hexagon',
		entry => [7,1,1], exit => [7,8,1],
		start => [1,4,1], fn_choosedir => \&first_dir
		);

$minos->make();
my $maze_form = $minos->to_ascii();
print +($maze_form ne $correct_make)? "not ok 2\n": "ok 2\n";

$minos->solve();
$maze_form = $minos->to_ascii();
print +($maze_form ne $correct_solve)? "not ok 3\n": "ok 3\n";

$maze_form = $minos->to_hex_dump();
print +($maze_form ne $correct_hex)? "not ok 4\n": "ok 4\n";

$minos->unsolve();
$maze_form = $minos->to_ascii();
print +($maze_form ne $correct_make)? "not ok 5\n": "ok 5\n";

exit(0);

sub first_dir
{
	return ${$_[0]}[0];
}
