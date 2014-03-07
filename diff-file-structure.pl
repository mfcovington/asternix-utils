#!/usr/bin/env perl
# Mike Covington
# created: 2014-01-16
#
# Description:
#
# Adapted from: http://stackoverflow.com/a/15214549/996114
#
use strict;
use warnings;
use autodie;
use feature 'say';
use File::Find;
use List::MoreUtils qw(uniq);
use Digest::MD5 'md5_base64';
use File::Slurp;
use Getopt::Long;

my $pattern = "(\\.CR2)|(\\.JPG)\$";
my ( $check_size, $check_content, $verbose, $help );

my $options = GetOptions(
    "pattern=s" => \$pattern,
    "size"      => \$check_size,
    "content"   => \$check_content,
    "verbose"   => \$verbose,
    "help"      => \$help,
);

my $dir1 = $ARGV[0] // "test1";
my $dir2 = $ARGV[1] // "test2";

usage_statement() if $help;
verify_dirs( $dir1, $dir2 );
my $files1 = get_files( $dir1, $pattern, $verbose );
my $files2 = get_files( $dir2, $pattern, $verbose );
compare_files( $files1, $files2, $dir1, $dir2, $verbose );

exit;

sub usage_statement {
    my $usage = <<EOF;
USAGE:
  $0 path_to_directory_1 path_to_directory_2 > output_file
    --pattern  Regular expression to limit comparisons to specific filetypes ["(\\.CR2)|(\\.JPG)\$"]
    --size     Compare sizes of file pairs
    --content  Compare content of file pairs
    --verbose
    --help
EOF

    die $usage;
}

sub verify_dirs {
    -d $_ or die "Directory '$_' does not exist.\n" for @_;
}

sub get_files {
    my ( $dir, $pattern, $verbose ) = @_;

    my %files;
    my $count = 0;

    select(STDERR);
    $| = 1;
    say "Finding files in '$dir'";

    find sub {
        die "Duplicate filename: '$_' at '$files{$_}{path} and $File::Find::name'\n"
            if exists $files{$_};
        return unless -f && m/$pattern/i;
        $files{$_}{path}   = $File::Find::name;
        $files{$_}{size}   = -s $_ if $check_size;
        $files{$_}{digest} = md5_base64( read_file($_) ) if $check_content;
        print "  $count files processed\r" if ++$count % 100 == 0;
    }, $dir;

    say "";
    select(STDOUT);

    return \%files;
}

sub compare_files {
    my ( $files1, $files2, $dir1, $dir2, $verbose ) = @_;

    my @all = uniq keys $files1, keys $files2;

    my %counts;

    for my $file ( sort @all ) {
        my $result;
        if ( exists $$files1{$file} && exists $$files2{$file} ) {
            verify_size_matches( $$files1{$file}, $$files2{$file} )
                if $check_size;
            verify_content_matches( $$files1{$file}, $$files2{$file} )
                if $check_content;
            $counts{Both}++;
            next;
        }
        elsif ( exists $$files1{$file} ) {
            $counts{"Only in $dir1"}++;
            say "<< '$file' only in '$dir1' at '$$files1{$file}{path}'" if $verbose;
        }
        elsif ( exists $$files2{$file} ) {
            $counts{"Only in $dir2"}++;
            say ">> '$file' only in '$dir2' at '$$files2{$file}{path}'" if $verbose;
        }
        else {
            die "Something went wrong...\n";
        }
    }

    say "$_: $counts{$_}" for sort keys %counts;
}

sub verify_size_matches {
    my ( $file_info1, $file_info2 ) = @_;

    return if $$file_info1{size} == $$file_info2{size};

    say <<EOF;
File names match, but sizes appear to be different:
  << '$$file_info1{path}' ($$file_info1{size})
  >> '$$file_info2{path}' ($$file_info2{size})
EOF
}

sub verify_content_matches {
    my ( $file_info1, $file_info2 ) = @_;

    return if $$file_info1{digest} eq $$file_info2{digest};

    say <<EOF;
File names match, but contents appear to be different:
  << '$$file_info1{path}'
  >> '$$file_info2{path}'
EOF
}
