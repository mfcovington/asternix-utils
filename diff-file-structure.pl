#!/usr/bin/env perl
# Mike Covington
# created: 2014-01-16
#
# Description:
#
use strict;
use warnings;
use autodie;
use feature 'say';
use File::Find;
use List::MoreUtils qw(uniq);

# Adapted from: http://stackoverflow.com/a/15214549/996114

my $dir1    = $ARGV[0] // "test1";
my $dir2    = $ARGV[1] // "test2";
my $pattern = $ARGV[2] // "(\\.CR2)|(\\.JPG)\$";
my $verbose = 1;

verify_dirs( $dir1, $dir2 );
my $files1 = get_files( $dir1, $pattern );
my $files2 = get_files( $dir2, $pattern );

my @all = uniq keys $files1, keys $files2;

my %counts;

for my $file ( sort @all ) {
    my $result;
    if ( exists $$files1{$file} && exists $$files2{$file} ) {
        $counts{Both}++;
        next;
    }
    elsif ( exists $$files1{$file} ) {
        $counts{"Only in $dir1"}++;
        say "<< '$file' only in '$dir1' at '$$files1{$file}'" if $verbose;
    }
    elsif ( exists $$files2{$file} ) {
        $counts{"Only in $dir2"}++;
        say ">> '$file' only in '$dir2' at '$$files2{$file}'" if $verbose;
    }
    else {
        die "Something went wrong...\n";
    }
}

say "$_: $counts{$_}" for sort keys %counts;

exit;

sub verify_dirs {
    -d $_ or die "Directory '$_' does not exist.\n" for @_;
}

sub get_files {
    my ( $dir, $pattern ) = @_;

    my %files;

    find sub {
        die "Duplicate filename: '$_' at '$files{$_} and $File::Find::name'\n"
            if exists $files{$_};
        -f && m/$pattern/i && ( $files{$_} = $File::Find::name );
    }, $dir;

    return \%files;
}
