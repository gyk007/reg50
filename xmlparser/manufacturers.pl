#!/usr/bin/perl
use strict;
use utf8;

use ALKO::Catalog::Manufacturer;
use XML::Simple;

my $manufacturers = XML::Simple->new;
my $manufacturers = $manufacturers->XMLin("$ENV{PWD}/../../../data/i/manufacturers.xml", KeyAttr => { manufacturer => 'id' });

while( my( $key, $value ) = each %{$manufacturers->{manufacturer}} ){
    ALKO::Catalog::Manufacturer->new({
		name   => $value->{name},
		alkoid => $key
    })->Save;
}

print "END \n";

1;