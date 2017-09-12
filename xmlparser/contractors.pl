#!/usr/bin/perl
use strict;

use ALKO::Client::Official;
use ALKO::Client::Net;
use ALKO::Client::Merchant;
use XML::Simple;

my $clients = XML::Simple->new;
my $clients = $clients->XMLin("$ENV{HOME}/data/i/contractors.xml", KeyAttr => { contractor => 'id' });

while( my( $key, $value ) = each %{$clients->{contractor}} ){
	# Добавляем реквизиты сети если их не существует, если существуют обнавляем
	my $official = ALKO::Client::Official->Get(alkoid => $key);
	unless ($official) {
		$official = ALKO::Client::Official->new({
			name          => defined $value->{name}                  ? $value->{name}                  : undef,
			person        => defined $value->{person}                ? $value->{person}                : undef,
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
			regcode       => defined $value->{ogrn}                  ? $value->{ogrn}                  : undef ,
			alkoid        => $key,
		});

		$official->{name}          = undef if ref $value->{name}                   eq 'HASH';
		$official->{address}       = undef if ref $value->{delivery_address}       eq 'HASH';
		$official->{person}        = undef if ref $value->{person}                 eq 'HASH';
		$official->{regaddress}    = undef if ref $value->{legal_address}          eq 'HASH';
		$official->{phone}         = undef if ref $value->{phonecontractor}        eq 'HASH';
		$official->{email}         = undef if ref $value->{email}                  eq 'HASH';
		$official->{bank}          = undef if ref $value->{bank}                   eq 'HASH';
		$official->{account}       = undef if ref $value->{account_number}         eq 'HASH';
		$official->{bank_account}  = undef if ref $value->{correspondent_account}  eq 'HASH';
		$official->{bik}           = undef if ref $value->{bik}                    eq 'HASH';
		$official->{taxcode}       = undef if ref $value->{inn}                    eq 'HASH';
		$official->{taxreasoncode} = undef if ref $value->{kpp}                    eq 'HASH';
		$official->{regcode}       = undef if ref $value->{ogrn}                   eq 'HASH';

		print "Добавлена организация: $key \n";
	} else {
		$official->{name}          = $value->{name}                  if ref $value->{name}                   ne 'HASH';
		$official->{address}       = $value->{delivery_address}      if ref $value->{delivery_address}       ne 'HASH';
		$official->{person}        = $value->{person}                if ref $value->{person}                 ne 'HASH';
		$official->{regaddress}    = $value->{legal_address}         if ref $value->{legal_address}          ne 'HASH';
		$official->{phone}         = $value->{phonecontractor}       if ref $value->{phonecontractor}        ne 'HASH';
		$official->{email}         = $value->{email}                 if ref $value->{email}                  ne 'HASH';
		$official->{bank}          = $value->{bank}                  if ref $value->{bank}                   ne 'HASH';
		$official->{account}       = $value->{account_number}        if ref $value->{account_number}         ne 'HASH';
		$official->{bank_account}  = $value->{correspondent_account} if ref $value->{correspondent_account}  ne 'HASH';
		$official->{bik}           = $value->{bik}                   if ref $value->{bik}                    ne 'HASH';
		$official->{taxcode}       = $value->{inn}                   if ref $value->{inn}                    ne 'HASH';
		$official->{taxreasoncode} = $value->{kpp}                   if ref $value->{kpp}                    ne 'HASH';
		$official->{regcode}       = $value->{ogrn}                  if ref $value->{ogrn}                   ne 'HASH';

		print "Обновлена организация: $key \n";
	}

	$official->Save;

	my $merchant = ALKO::Client::Merchant->Get(alkoid => $key);

	# Добавляем представителя если его не существует
	$merchant = ALKO::Client::Merchant->new({
		alkoid => $key,
	})->Save unless $merchant;

	# Добавляем организацию если не ее существует
	my $net = ALKO::Client::Net->Get(id_official => $official->id);
	$net = ALKO::Client::Net->new({
		id_official => $official->id,
		id_merchant => $merchant->id,
	})->Save unless $net;
}

print "END \n";

1;