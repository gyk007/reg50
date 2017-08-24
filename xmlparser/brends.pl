#!/usr/bin/perl
use strict;

# use ALKO::Catalog::Manufacturer;
# use ALKO::Catalog::Brand;
# use XML::Simple;

# my $brends = XML::Simple->new;
# my $brends = $brends->XMLin("$ENV{PWD}/../../../data/i/brends.xml", KeyAttr => { brand => 'id' });

# while( my( $alkoid, $brand ) = each %{$brends->{brand}} ){
#     my $manufacturer    = ALKO::Catalog::Manufacturer->Get(alkoid =>  $brand->{manufacturer});
#     my $manufacturer_id = $manufacturer ? $manufacturer->{id} : undef;

#     ALKO::Catalog::Brand->new({
#    		id_manufacturer => $manufacturer_id,
# 		name            => $brand->{name},
# 		alkoid          => $alkoid,
#     })->Save;
# }

print "END \n";

1;