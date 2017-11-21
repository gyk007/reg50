#! /usr/bin/perl
#
# Категории. Дерево каталога.
#

use strict;
use warnings;

use 5.014;
no warnings 'experimental::smartmatch';

use List::Util qw( min max );
use WooF::Debug;
use ALKO::Server;
use ALKO::Catalog;
use ALKO::Catalog::Category;
use ALKO::Catalog::Category::Graph;
use ALKO::Client::Offer;
use ALKO::Catalog::Product;
use ALKO::Catalog::Property;
use ALKO::Catalog::Property::Value;
use ALKO::Country;
use ALKO::Catalog::Brand;
use ALKO::Catalog::Manufacturer;
use POSIX qw(strftime);
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

		$category->complete_products;

		for ($category->products->List) {
			# Цена для данного товара, чтобы не делать лишний запрос к базе в методе price
			my $price = $_->{Price};
			# Если это уберем то при $offer->{$_->{id} = undef метод price сделает ненужный запрос в базу,
			$offer->{$_->{id}} = 1 unless $offer->{$_->{id}};
			# Расчимтываем скидку для продукта, передаем id магазина, массив скидок и цену.
			$_->price($O->{SESSION}->id_shop, $offer->{$_->{id}}, $price);
		};

		# Чистим структуру для вывода
		$category->{products} = $category->{extend}{products}{elements};
		delete $category->{groups_effective};
		delete $category->{extend};

		$O->{category} = $category;


		OK;
	},
});


# Список катагорий
# URL: /catalog/category/?search=string
$Server->add_handler(SEARCH => {
	input => {
		allow => ['search'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $q = qq{SELECT * FROM product WHERE lower(name) LIKE lower(?)};

		my @search_param = (
			name => "%$I->{search}%",
		);

		my $search = $S->D->fetch_all($q, @search_param);

		my @id;
		push @id, $_->{id} for @$search;

		my $products = ALKO::Catalog::Product->All(id => \@id);

		my $property = ALKO::Catalog::Property->All;
		my $prop_val = ALKO::Catalog::Property::Value->All(id_product => \@id);

		my $countries     = ALKO::Country->All->Hash;
		my $brands        = ALKO::Catalog::Brand->All->Hash;
		my $manufacturers = ALKO::Catalog::Manufacturer->All->Hash;

		# Массивы для фильтров
		my @filter_price;
		my @filter_alko;

		# Создаем стуктуру %prod_prop{ид товара}[{name => "Price", n}]= значение
 		my %prod_prop;
		for my $val ($prop_val->List) {
		    for my $prop ($property->List) {
		    	given ($prop->name) {
					when ('Qty') {
						if ($val->id_propgroup == $prop->id_propgroup and  $val->n_property == $prop->n) {
							push @{$prod_prop{$val->id_product}}, {name => $prop->name, value => $val->val_int};
							last;
						}
					}
					when ('Litr') {
						if ($val->id_propgroup == $prop->id_propgroup and  $val->n_property == $prop->n) {
							push @{$prod_prop{$val->id_product}}, {name => $prop->name, value => $val->val_float};
							last;
						}
					}
					when ('Pack') {
						if ($val->id_propgroup == $prop->id_propgroup and  $val->n_property == $prop->n) {
							push @{$prod_prop{$val->id_product}}, {name => $prop->name, value => $val->val_int};
							last;
						}
					}
					when ('Price') {
						if ($val->id_propgroup == $prop->id_propgroup and  $val->n_property == $prop->n) {
							push @{$prod_prop{$val->id_product}}, {name => $prop->name, value => $val->val_dec};
							push @filter_price,  $val->val_dec;
							last;
						}
					}
					when ('Alko') {
						if ($val->id_propgroup == $prop->id_propgroup and  $val->n_property == $prop->n) {
							push @{$prod_prop{$val->id_product}}, {name => $prop->name, value => $val->val_float};
							push @filter_alko,  $val->val_float;
							last;
						}
					}
					when ('Brand') {
						if ($val->id_propgroup == $prop->id_propgroup and  $val->n_property == $prop->n) {
							my $brand = $brands->{$val->val_int}->name;
							push @{$prod_prop{$val->id_product}}, {name => $prop->name, value => $brand};
							last;
						};
					}
					when ('Made in') {
						if ($val->id_propgroup == $prop->id_propgroup and  $val->n_property == $prop->n) {
							my $country = $countries->{$val->val_int}->name;
							push @{$prod_prop{$val->id_product}}, {name => $prop->name, value => $country};
							last;
						};
					}
					when ('Manufacturer') {
						if ($val->id_propgroup == $prop->id_propgroup and  $val->n_property == $prop->n) {
							my $manufacturer = $manufacturers->{$val->val_int}->name;
							push @{$prod_prop{$val->id_product}}, {name => $prop->name, value => $manufacturer};
							last;
						};
					}
					default {
						if ($val->id_propgroup == $prop->id_propgroup and  $val->n_property == $prop->n) {
							push @{$prod_prop{$val->id_product}}, {name => $prop->name, value => $val->val_int};
							last;
						}
					}
				}
		    }
		}

		# Добаляем свойсвта в товар
		$_->properties($prod_prop{$_->{id}}) for $products->List;

		# Получаем скидки для торговой точки
		my $offer = ALKO::Client::Offer->All(id_shop => $O->{SESSION}->id_shop)->Hash('id_product');

		# Расчитываем скидку
		for ($products->List) {
			# Цена для данного товара, чтобы не делать лишний запрос к базе в методе price
			my $price;
			for (@{$_->properties}) {
				$price = $_->{value} if $_->{name} eq 'Price';
			}
			# Если это уберем то при $offer->{$_->{id} = undef метод price сделает ненужный запрос в базу,
			$offer->{$_->{id}} = 1 unless $offer->{$_->{id}};
			# Расчимтываем скидку для продукта, передаем id магазина, массив скидок и цену.
			$_->price($O->{SESSION}->id_shop, $offer->{$_->{id}}, $price);
		};

		# Значения фильтров
		my $filter = {
			alko => {
				max => scalar @filter_alko ? max @filter_alko : 0,
				min => scalar @filter_alko ? min @filter_alko : 0,
			},
			price => {
				max => scalar @filter_price ? max @filter_price : 0,
				min => scalar @filter_price ? min @filter_price : 0,
			}
		};

		$O->{filter}   =  $filter;
		$O->{products} = $products->List;

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
	return ['ITEM']   if exists $I->{id};
	return ['SEARCH'] if exists $I->{search};

	['LIST'];
});

$Server->listen;
