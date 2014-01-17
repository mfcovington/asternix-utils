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

my %files1;
my %files2;

find sub {
    die "Duplicate filename: '$_' at '$files1{$_} and $File::Find::name'\n"
        if exists $files1{$_};
    -f && m/$pattern/i && ( $files1{$_} = $File::Find::name );
}, $dir1;

find sub {
    die "Duplicate filename: '$_' at '$files2{$_} and $File::Find::name'\n"
        if exists $files2{$_};
    -f && m/$pattern/i && ( $files2{$_} = $File::Find::name );
}, $dir2;

my @all = uniq keys %files1, keys %files2;

my %counts;

for my $file ( sort @all ) {
    my $result;
    if ( exists $files1{$file} && exists $files2{$file} ) {
        $counts{Both}++;
        next;
    }
    elsif ( exists $files1{$file} ) {
        $counts{"Only in $dir1"}++;
        say "<< '$file' only in '$dir1' at '$files1{$file}'" if $verbose;
    }
    elsif ( exists $files2{$file} ) {
        $counts{"Only in $dir2"}++;
        say ">> '$file' only in '$dir2' at '$files2{$file}'" if $verbose;
    }
    else {
        die "Something went wrong...\n";
    }
}

say "$_: $counts{$_}" for sort keys %counts;

