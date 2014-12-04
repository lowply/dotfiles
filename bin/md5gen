#!/usr/bin/perl
use Digest::MD5 qw(md5 md5_hex md5_base64);
my $pass = $ARGV[0];
chomp $pass;
my $salt = WDQprvTD4fAijyqAEGm;
my $hex = md5_base64($salt.$pass);
my $subst = substr($hex, 8, 8);
print "Digest : ", $hex, "\n";
print "Password : ", $subst, "\n";
