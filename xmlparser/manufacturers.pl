#!/usr/bin/perl
use strict;

use ALKO::Catalog::Manufacturer;
use XML::Simple;

debug "START \n";

my $manufacturers = XML::Simple->new;
my $manufacturers = $manufacturers->XMLin("$ENV{HOME}/data/i/manufacturers.xml", KeyAttr => { manufacturer => 'id' });

while( my( $alkoid, $manufacturer ) = each %{$manufacturers->{manufacturer}} ){
    # Если есть обновляем, если нет добавляем
    my $manufact = ALKO::Catalog::Manufacturer->Get(alkoid => $alkoid);
    if($manufact) {
    	$manufact->{name} = $manufacturer->{name};
   	} else {
   		$manufact = ALKO::Catalog::Manufacturer->new({
  			name   => $manufacturer->{name},
  			alkoid => $alkoid
    	});
   	}

   	$manufact->Save;
}

debug "END \n";

1;