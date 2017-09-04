#!/usr/bin/perl
use strict;

use ALKO::Client::Shop;
use ALKO::Client::Net;
use ALKO::Client::Official;
use ALKO::Client::Merchant;
use ALKO::Client::Offer;
use ALKO::Client::ArciveOffer;
use ALKO::Catalog::Product;
use ALKO::Cart;
use DateTime;
use WooF::DB;
use XML::Simple;
use WooF::Debug;

my $clients = XML::Simple->new;
my $clients = $clients->XMLin("$ENV{PWD}/../../../data/i/trade_points.xml", KeyAttr => { trade_point => 'id' });

# Удаляем все индивидуальные предложения
my $q = qq{	DELETE FROM archive_offer};
ALKO::Client::ArciveOffer->S->D->exec($q) or die "ERROR SQL: $q";

while( my( $key, $value ) = each %{$clients->{trade_point}} ){
	# Добавляем представителя если его не существует
	my $merchant   = ALKO::Client::Merchant->Get(alkoid => $key);
	$merchant = ALKO::Client::Merchant->new({
		alkoid => $key,
	})->Save unless $merchant;

	# Добавляем реквизиты торговой точки если их не существует, или обновляем
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

		print "Добавлена торговая точка: $key \n";
	} else {
		$official->{name}          = $value->{name}             if ref $value->{name}             ne 'HASH';
		$official->{address}       = $value->{delivery_address} if ref $value->{delivery_address} ne 'HASH';
		$official->{taxreasoncode} = $value->{kpp}              if ref $value->{kpp}              ne 'HASH';

		print "Обновлена торговая точка: $key \n";
	}
	$official->Save;

	# Получаем организацию
	my $net_official = ALKO::Client::Official->Get(alkoid => $value->{id_contractor});
	my $net          = ALKO::Client::Net->Get(id_official => $net_official->{id});

	# Добавляем магазин если его не существует или обновляем
	my $shop = ALKO::Client::Shop->Get(id_official => $official->id);
	unless ($shop) {
		$shop = ALKO::Client::Shop->new({
			id_official => $official->id,
			id_net      => $net->id,
			id_merchant => $merchant->id,
		});
	} else {
		$shop->{id_net} = $net->id;
	}
	$shop->Save;

	# Добавлям корзину для магазина если не существует
	my $cart = ALKO::Cart->Get(id_shop => $shop->id);
	$cart = ALKO::Cart->new({
		id_shop => $shop->id,
		n       => 1,
	})->Save unless $cart;

	# Индивидуальные предложения
	if($value->{offers}{product}){
		if (ref $value->{offers}{product} eq 'ARRAY'){
			for (@{$value->{offers}{product}}) {
				my $prod = ALKO::Catalog::Product->Get(alkoid => $_->{id});

				if ($prod and $_->{discount}{content}) {
					# Проверяем есть ли скидка,
					# Если есть то при условии что там старая дата - обнавляем
					my $disc = ALKO::Client::Offer->Get(id_product => $prod->{id}, id_shop => $shop->id);
					if($disc) {
						# Парсим дату xml
						my ($year_xml, $month_xml, $day_xml)  = split('-', $_->{date});
						my $date_xml = DateTime->new(
							year   => $year_xml,
							month  => $month_xml,
							day    => $day_xml,
						);

						# Парсим дату из базы
						my ($date_temp, $time_temp)        = split(' ', $disc->{ctime});
						my ($year_db, $month_db, $day_db)  = split('-', $date_temp);
						my $date_db = DateTime->new(
							year  => $year_db,
							month => $month_db,
							day   => $day_db,
						);

						# Если в xml свежая дата то обнавляем скидку
						if($date_db->epoch < $date_xml->epoch) {
							$disc->{type}  = $_->{discount}{type};
							$disc->{value} = $_->{discount}{content};
							$disc->{ctime} = $_->{date};
							$disc->Save;
						}
					} else {
						$disc = ALKO::Client::Offer->new({
							id_shop    => $shop->id,
							id_product => $prod->id,
							type       => $_->{discount}{type},
							value      => $_->{discount}{content},
							ctime      => $_->{date},
						})->Save;
					}

					# Архив скидок
					ALKO::Client::ArciveOffer->new({
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

				# Архив скидок
				ALKO::Client::ArciveOffer->new({
					id_shop    => $shop->id,
					id_product => $prod->id,
					type       => $_->{discount}{type},
					value      => $_->{discount}{content},
					ctime      => $_->{date},
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