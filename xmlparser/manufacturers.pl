#!/usr/bin/perl
use strict;

use ALKO::Catalog::Manufacturer;
use XML::Simple;

my $manufacturers = XML::Simple->new;
my $manufacturers = $manufacturers->XMLin("$ENV{PWD}/../../../data/i/manufacturers.xml", KeyAttr => { manufacturer => 'id' });

while( my( $alkoid, $manufacturer ) = each %{$manufacturers->{manufacturer}} ){
    ALKO::Catalog::Manufacturer->new({
		name   => $manufacturer->{name},
		alkoid => $alkoid
    })->Save;
}

print "END \n";

1;