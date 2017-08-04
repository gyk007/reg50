#!/usr/bin/perl
use strict;

use ALKO::Catalog::Manufacturer;
use ALKO::Catalog::Brand;
use XML::Simple;

my $brends = XML::Simple->new;
my $brends = $brends->XMLin("$ENV{PWD}/../../../data/i/brends.xml", KeyAttr => { brand => 'id' });

while( my( $key, $value ) = each %{$brends->{brand}} ){
   my $manufacturer = ALKO::Catalog::Manufacturer->Get(alkoid =>  $value->{manufacturer});
   my $manufacturer_id = $manufacturer ? $manufacturer->{id} : undef;

   ALKO::Catalog::Brand->new({
   		id_manufacturer => $manufacturer_id,
		name            => $value->{name},
		alkoid          => $key,
   })->Save;
}

print "END \n";

1;