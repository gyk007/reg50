#!/usr/bin/perl
use strict;

use ALKO::Client::Shop;
use ALKO::Client::Net;
use ALKO::Client::Official;
use ALKO::Client::Merchant;
use ALKO::Cart;
use XML::Simple;
use Data::Dumper;

my $clients = XML::Simple->new;
my $clients = $clients->XMLin("$ENV{PWD}/../../../data/i/trade_points.xml", KeyAttr => { trade_point => 'id' });

while( my( $key, $value ) = each %{$clients->{trade_point}} ){
	my $contractor = ALKO::Client::Official->Get(alkoid => $value->{id_contractor});
	my $merchant   = ALKO::Client::Merchant->Get(alkoid => $value->{id_contractor});

	# Добавляем представителя если его не существует
	unless ($merchant) {
		$merchant = ALKO::Client::Merchant->new({
			phone  => $value->{person}{phoneperson} ? $value->{person}{phoneperson} : undef,
			name   => $value->{person}{content}     ? $value->{person}{content} : undef,
			alkoid => $value->{id_contractor},
		})->Save if ref $value->{person} eq 'HASH';

		$merchant = ALKO::Client::Merchant->new({
			name   => $value->{person} ? $value->{person} : undef,
			alkoid => $value->{id_contractor},
		})->Save unless ref $value->{person} eq 'HASH';

		# Добавлям корзину для пользователя
		ALKO::Cart->new({
			id_merchant => $merchant->{id},
			n           => 1,
		})->Save;
	}

	# Добавляем организацию если не ее существует
	my $net = ALKO::Client::Net->Get(id_official => $contractor->{id}, id_merchant => $merchant->{id});
	$net = ALKO::Client::Net->new({
		id_official => $contractor->{id},
		id_merchant => $merchant->{id},
	})->Save unless $net;

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

	# Добавляем магазин если его не существует
	my $shop = ALKO::Client::Shop->Get(id_official => $official->{id});
	$shop = ALKO::Client::Shop->new({
		id_merchant => $merchant->{id},
		id_official => $official->{id},
		id_net      => $net->{id},
	})->Save unless $shop;
}

print "END \n";

1;