use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use File::Spec;
use File::Path;
use Cwd qw( abs_path );
use Git::Repository;

plan tests => my $tests;

# clean up the environment
delete @ENV{qw( GIT_DIR GIT_WORK_TREE )};

# a place to put a git repository
my $tmp = tempdir( CLEANUP => 1 );

# some dirname generating routine
my $i;
sub next_dir {
    my $dir = File::Spec->catdir( $tmp, ++$i );
    mkpath $dir if @_;
    return $dir;
}

my ( $dir, $r );
$dir = next_dir;

# PASS - non-existent directory
BEGIN { $tests += 4 }
ok( $r = eval { $r = Git::Repository->create( init => $dir ); },
    "create( init => $i )" );
diag $@ if $@;
isa_ok( $r, 'Git::Repository' );
is( $r->repo_path,
    File::Spec->catdir( $dir, '.git' ),
    '... correct repo_path'
);
is( $r->wc_path, $dir, '... correct wc_path' );

# FAIL - command doesn't initialize a git repository
BEGIN { $tests += 2 }
ok( !( $r = eval { Git::Repository->create('--version'); } ),
    "create( --version ) FAILED" );
diag $@ if $@;
is( $r, undef, 'create( log ) did not create a repository' );

# PASS - clone an existing repo and warns
BEGIN { $tests += 4 }
my $old = $dir;
$dir = next_dir;
ok( $r = eval { Git::Repository->create( clone => $old => $dir ); },
    "create( clone => @{[ $i - 1 ]} => $i )" );
diag $@ if $@;
isa_ok( $r, 'Git::Repository' );
is( $r->repo_path,
    File::Spec->catdir( $dir, '.git' ),
    '... correct repo_path'
);
is( $r->wc_path, $dir, '... correct wc_path' );

# FAIL - clone a non-existing repo
BEGIN { $tests += 3 }
$old = next_dir;
$dir = next_dir;
ok( !( $r = eval { Git::Repository->create( clone => $old => $dir ); } ),
    "create( clone => @{[ $i - 1 ]} => $i ) FAILED" );
is( $r, undef,
    "create( clone => @{[ $i - 1 ]} => $i ) did not create a repository" );
like( $@, qr/^fatal: /, 'fatal error from git' );

# FAIL - init a dir that is a file
BEGIN { $tests += 3 }
$dir = next_dir;
{ open my $fh, '>', $dir; }    # creates an empty file
ok( !( $r = eval { $r = Git::Repository->create( init => $dir ); } ),
    "create( init => $i ) FAILED" );
is( $r, undef, "create( init => $i ) did not create a repository" );
like( $@, qr/^fatal: /, 'fatal error from git' );

# PASS - init a bare repository
BEGIN { $tests += 4 }
$dir = next_dir;
ok( $r = eval { Git::Repository->create( qw( init --bare ), $dir ); },
    "create( clone => @{[ $i - 1 ]} => $i )" );
diag $@ if $@;
isa_ok( $r, 'Git::Repository' );
is( $r->repo_path, $dir,  '... correct repo_path' );
is( $r->wc_path,   undef, '... correct wc_path' );
