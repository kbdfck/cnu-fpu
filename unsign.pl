#!/usr/bin/perl
#Cisco firmware/package signature remover
#Written by kbdfck, 2007
#http://virtualab.ru

use strict;
use warnings;

sub usage {
    print STDERR "Usage:\n";
    print STDERR "$0 <input file> <file type> <output file>\n";
    print STDERR "File type can be 'gz' for main firmware archive or 'cnu' for firmware files\n";
    exit();
}

sub check_sign {
    my $buffer = $_[0];
    my $sign   = $_[1];
    return index( $buffer, $sign );
}

##################################################################

my $sign;

my $input_file  = $ARGV[0] || usage();
my $type        = $ARGV[1] || usage();
my $output_file = $ARGV[2] || usage();

if ( $type eq 'gz' ) {
    $sign = "\x1f\x8b\x08";    #tar.gz firmware package
}

if ( $type eq 'cnu' ) {
    $sign = "CNU_";            #CNU firmware file
}

die "Unknown file type $type" unless $sign;

my $buf;
open( F, "<",$input_file ) or die "Can't open input file $input_file: $!";
binmode(F);
read( F, $buf, 500 );

my $offset = check_sign( $buf, $sign );
if ( $offset >= 0 ) {
    printf "Found signature offset: %s\n", $offset;
}
else {
    print "Signature not found\n";
    exit;
}

die "Can't seek to $offset" unless seek( F, $offset, 0 );
open( OF, ">", $output_file ) || die "Can't open output file $output_file: $!";
binmode(OF);

while ( read( F, $buf, 2048 ) ) {
    print OF $buf;
}
close(F);
close(OF);
