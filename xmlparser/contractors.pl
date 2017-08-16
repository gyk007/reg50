#!/usr/bin/perl
use strict;

use ALKO::Client::Official;
use XML::Simple;

my $clients = XML::Simple->new;
my $clients = $clients->XMLin("$ENV{PWD}/../../../data/i/contractors.xml", KeyAttr => { contractor => 'id' });

while( my( $key, $value ) = each %{$clients->{contractor}} ){
	# Реквизиты
	my $official = ALKO::Client::Official->new({
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
		regcode       => defined $value->{ogrn}                  ? $value->{ogrn}                  : undef,
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

	$official->Save;
}

print "END \n";

1;