#!/usr/bin/env perl
#
# $Id: ezip.pl,v 0.1 2010/09/06 13:52:00 dankogai Exp dankogai $
#
use strict;
use warnings;
use Archive::Zip qw/:ERROR_CODES/;
use Getopt::Std;
use Encode;
use Unicode::Normalize;    # to handle UTF-8-MAC

my %opt = ( e => 'UTF-8' );
getopts( "e:" => \%opt );
my $encode = do {
    my $enc = find_encoding( $opt{e} ) or die "unknown encoding: $opt{e}";
    sub { $enc->encode( Unicode::Normalize::NFC( decode_utf8(shift) ) ) };
};

my $zipfile = shift; 
die "$0 -e encoding archive.zip path ..." unless @ARGV;
my $zip = Archive::Zip->new;
$zip->addTree($_, $_) for @ARGV;
my $error;
for my $m ( $zip->members() ) {
    $m->fileName( $encode->( $m->fileName ) );
}
$error = $zip->writeToFileNamed($zipfile) and die "$zipfile : error $error";
