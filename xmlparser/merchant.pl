#!/usr/bin/perl
use strict;

use ALKO::Client::Shop;
use ALKO::Client::Net;
use ALKO::Client::Official;
use ALKO::Client::Merchant;
use ALKO::Cart;
use XML::Simple;

my $clients = XML::Simple->new;
my $clients = $clients->XMLin("$ENV{PWD}/../../../data/i/clients.xml", KeyAttr => { contractor => 'id' });

while( my( $key, $value ) = each %{$clients->{contractor}} ){
	my $merchant = ALKO::Client::Merchant->new({
		password => $value->{password}        ? $value->{password}        : '1111111',
		phone    => $value->{phonecontractor} ? $value->{phonecontractor} : undef,
		email    => $key,
		name     => $value->{person},
		alkoid   => $key,
	})->Save;

	my $official = ALKO::Client::Official->new({
		name          => defined $value->{name}                  ? $value->{name}                  : undef,
		address       => defined $value->{delivery_address}      ? $value->{delivery_address}      : undef,
		regaddress    => defined $value->{legal_address}         ? $value->{legal_address}         : undef,
		phone         => defined $value->{phonecontractor}       ? $value->{phonecontractor}       : undef,
		email         => defined $value->{email}                 ? $value->{email}                 : undef,
		bank          => defined $value->{bank}                  ? $value->{bank}                  : undef,
		account       => defined $value->{account_number}        ? $value->{account_number}        : undef,
		bank_account  => defined $value->{correspondent_account} ? $value->{correspondent_account} : undef,
		bik           => defined $value->{bik}                   ? $value->{bik}                   : undef,
		taxcode       => defined $value->{inn}                   ? $value->{inn}                   : undef,
		taxreasoncode => defined $value->{kpp}                   ? $value->{kpp}                   : undef,
		regcode       => defined $value->{ogrn}                  ? $value->{ogrn}                  : undef,
		alkoid        => $key,
	});

	$official->{address}       = undef if ref $official->{address}       eq 'HASH';
	$official->{regaddress}    = undef if ref $official->{regaddress}    eq 'HASH';
	$official->{phone}         = undef if ref $official->{phone}         eq 'HASH';
	$official->{email}         = undef if ref $official->{email}         eq 'HASH';
	$official->{bank}          = undef if ref $official->{bank}          eq 'HASH';
	$official->{account}       = undef if ref $official->{account}       eq 'HASH';
	$official->{bank_account}  = undef if ref $official->{bank_account}  eq 'HASH';
	$official->{bik}           = undef if ref $official->{bik}           eq 'HASH';
	$official->{taxcode}       = undef if ref $official->{taxcode}       eq 'HASH';
	$official->{taxreasoncode} = undef if ref $official->{taxreasoncode} eq 'HASH';
	$official->{regcode}       = undef if ref $official->{regcode}       eq 'HASH';

	$official->Save;

	ALKO::Client::Shop->new({
		id_merchant => $merchant->{id},
		id_official => $official->{id},
	})->Save;

	ALKO::Cart->new({
		id_merchant => $merchant->{id},
	 	n           => 1,
	})->Save;
}

print "END \n";

1;