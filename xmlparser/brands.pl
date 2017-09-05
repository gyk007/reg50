#!/usr/bin/perl
use strict;

use ALKO::Catalog::Manufacturer;
use ALKO::Catalog::Brand;
use XML::Simple;

my $brends = XML::Simple->new;
$brends = $brends->XMLin("$ENV{PWD}/../../../data/i/brands.xml", KeyAttr => { brand => 'id' });

while( my( $alkoid, $brand ) = each %{$brends->{brand}} ){
    my $manufacturer    = ALKO::Catalog::Manufacturer->Get(alkoid =>  $brand->{manufacturer});
    my $manufacturer_id = $manufacturer ? $manufacturer->{id} : undef;

    # Если есть обновляем, если нет добавляем
    my $br = ALKO::Catalog::Brand->Get(alkoid => $alkoid);
    if ($br) {
    	$br->{name}            = $brand->{name};
    	$br->{id_manufacturer} = $manufacturer_id;

    	print "Обновили бренд: $alkoid \n";
    } else {
    	$br = ALKO::Catalog::Brand->new({
	   		id_manufacturer => $manufacturer_id,
			name            => $brand->{name},
			alkoid          => $alkoid,
    	});
    	print "Добавили бренд: $alkoid \n";
    }

    $br->Save;
}

print "END \n";

1;