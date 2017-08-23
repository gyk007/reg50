#!/usr/bin/perl
use strict;

use ALKO::Client::Official;
use XML::Simple;

my $clients = XML::Simple->new;
my $clients = $clients->XMLin("$ENV{PWD}/../../../data/i/contractors.xml", KeyAttr => { contractor => 'id' });

while( my( $key, $value ) = each %{$clients->{contractor}} ){
	# Реквизиты
	my $official = ALKO::Client::Official->new({
		name          => $value->{name}                  if defined $value->{name},
		person        => $value->{person}                if defined $value->{person},
		address       => $value->{delivery_address}      if defined $value->{delivery_address},
		regaddress    => $value->{legal_address}         if defined $value->{legal_address},
		phone         => $value->{phonecontractor}       if defined $value->{phonecontractor},
		email         => $value->{email}                 if defined $value->{email},
		bank          => $value->{bank}                  if defined $value->{bank},
		account       => $value->{account_number}        if defined $value->{account_number},
		bank_account  => $value->{correspondent_account} if defined $value->{correspondent_account},
		bik           => $value->{bik}                   if defined $value->{bik},
		taxcode       => $value->{inn}                   if defined $value->{inn},
		taxreasoncode => $value->{kpp}                   if defined $value->{kpp},
		regcode       => $value->{ogrn}                  if defined $value->{ogrn},
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