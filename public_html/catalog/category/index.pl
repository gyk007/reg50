#! /usr/bin/perl
#
# Категории. Дерево каталога.
#

use strict;
use warnings;

use WooF::Debug;
use ALKO::Server;
use ALKO::Catalog;
use ALKO::Catalog::Category;
use ALKO::Catalog::Category::Graph;
use ALKO::Client::Offer;

my $Server = ALKO::Server->new(output_t => 'JSON', auth => 1);

# Определенная категория с товарами, свойствами, значениями.
# URL: /catalog/category/?id=125
$Server->add_handler(ITEM => {
	input => {
		allow => ['id'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);
		my $id = $I->{id};

		my $category = ALKO::Catalog::Category->Get(id => $id, EXPAND => [qw/ products propgroups /]) or return $S->fail("Can't get Category($id)");

		my $offer = ALKO::Client::Offer->All(id_shop => $O->{SESSION}->id_shop)->Hash('id_product');

		foreach ($category->products->List) {
			# # Цена для данного товара, чтобы не делать лишний запрос к базе в методе price
			# my $price = $_->{properties}{elements}[0]{extend}{properties}{elements}[0]{value};
			# # Если это уберем то при $offer->{$_->{id} = undef метод price сделает ненужный запрос в базу,
			# $offer->{$_->{id}} = 1 unless $offer->{$_->{id}};
			# # Расчимтываем скидку для продукта, передаем id магазина, массив скидок и цену.
			# $_->price($O->{SESSION}->id_shop, $offer->{$_->{id}}, $price);
		};

		# $O->{category} = $category->complete_products;

		OK;
	},
});

# Список катагорий
# URL: /catalog/category/
$Server->add_handler(LIST => {
	input => {
		allow => [],
	},
	call => sub {
		my $S = shift;

		$S->O->{categories} = ALKO::Catalog::Category->All(SORT => 'DEFAULT')->List;

		OK;
	},
});

$Server->dispatcher(sub {
	my $S = shift;
	my $I = $S->I;

	return ['ITEM'] if exists $I->{id};

	['LIST'];
});

$Server->listen;
