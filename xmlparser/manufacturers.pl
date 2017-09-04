#!/usr/bin/perl
use strict;

use ALKO::Catalog::Manufacturer;
use XML::Simple;

my $manufacturers = XML::Simple->new;
my $manufacturers = $manufacturers->XMLin("$ENV{PWD}/../../../data/i/manufacturers.xml", KeyAttr => { manufacturer => 'id' });

while( my( $alkoid, $manufacturer ) = each %{$manufacturers->{manufacturer}} ){
    # Если есть обновляем, если нет добавляем
    my $manufact = ALKO::Catalog::Manufacturer->Get(alkoid => $alkoid);
    if($manufact) {
    	$manufact->{name} = $manufacturer->{name};
    	print "Обновлен производитель: $alkoid \n";
   	} else {
   		$manufact = ALKO::Catalog::Manufacturer->new({
			name   => $manufacturer->{name},
			alkoid => $alkoid
    	});
    	print "Добавлен производитель: $alkoid \n";
   	}

   	$manufact->Save;
}

print "END \n";

1;