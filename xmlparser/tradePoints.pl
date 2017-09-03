#!/usr/bin/perl
use strict;

use ALKO::Client::Shop;
use ALKO::Client::Net;
use ALKO::Client::Official;
use ALKO::Client::Merchant;
use ALKO::Client::Offer;
use ALKO::Catalog::Product;
use ALKO::Cart;
use XML::Simple;
use WooF::Debug;

my $clients = XML::Simple->new;
my $clients = $clients->XMLin("$ENV{PWD}/../../../data/i/trade_points.xml", KeyAttr => { trade_point => 'id' });

while( my( $key, $value ) = each %{$clients->{trade_point}} ){
	# Добавляем представителя если его не существует
	my $merchant   = ALKO::Client::Merchant->Get(alkoid => $key);	 
	$merchant = ALKO::Client::Merchant->new({			 
		alkoid => $key,
	})->Save unless $merchant; 	 
 
	# Добавляем реквизиты торговой точки если их не существует
	my $official = ALKO::Client::Official->Get(alkoid => $key);
	unless ($official) {
		$official = ALKO::Client::Official->new({
			name          => defined $value->{name}             ? $value->{name}             : undef,
			address       => defined $value->{delivery_address} ? $value->{delivery_address} : undef,
			taxreasoncode => defined $value->{kpp}              ? $value->{kpp}              : undef,
			alkoid        => $key,
		});

		$official->{name}          = undef if ref $value->{name}             eq 'HASH';
		$official->{address}       = undef if ref $value->{delivery_address} eq 'HASH';
		$official->{taxreasoncode} = undef if ref $value->{kpp}              eq 'HASH';

		$official->Save;
	}

	# Получаем организацию
	my $net_official = ALKO::Client::Official->Get(alkoid => $value->{id_contractor});	 
	my $net          = ALKO::Client::Net->Get(id_official => $net_official->{id});

	# Добавляем магазин если его не существует
	my $shop = ALKO::Client::Shop->Get(id_official => $official->id);
	$shop = ALKO::Client::Shop->new({
		id_official => $official->id,
		id_net      => $net->id,
		id_merchant => $merchant->id,
	})->Save unless $shop;

	# Добавлям корзину для магазина
	ALKO::Cart->new({
		id_shop => $shop->id,
		n       => 1,
	})->Save;

	debug $shop->id;

	# Индивидуальные предложения
	if($value->{offers}{product}){
		if (ref $value->{offers}{product} eq 'ARRAY'){			
			for (@{$value->{offers}{product}}) {
				my $prod = ALKO::Catalog::Product->Get(alkoid => $_->{id});
				if ($prod and $_->{discount}{content}) {
					ALKO::Client::Offer->new({
						id_shop    => $shop->id,
						id_product => $prod->id,
						type       => $_->{discount}{type},
						value      => $_->{discount}{content},
						ctime      => $_->{date},
					})->Save;
				} elsif(!$prod) {
					print "Такого товара не существует\n"
				} else {
					print "Нулевая скидка\n"
				}
			}
		} 
		elsif (ref $value->{offers}{product} eq 'HASH') {
			my $prod = ALKO::Catalog::Product->Get(alkoid => $value->{offers}{product}{id});
			if ($prod and $_->{discount}{content}) {
				ALKO::Client::Offer->new({
					id_shop    => $shop->id,
					id_product => $prod->id,
					type       => $value->{offers}{product}{discount}{type},
					value      => $value->{offers}{product}{discount}{content},
					ctime      => $value->{offers}{product}{date},
				})->Save;
			} elsif (!$prod) {
				print "Такого товара не существует\n"
			} else {
				print "Нулевая скидка\n"
			}
		}
	}

}

print "END \n";

1;