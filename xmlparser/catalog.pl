#!/usr/bin/perl
use strict;

use XML::Simple;
use Data::Dumper;
use ALKO::Catalog;
use ALKO::Catalog::Category;
use ALKO::Catalog::Category::Graph;
use ALKO::Catalog::Product;
use ALKO::Catalog::Product::Link;
use ALKO::Catalog::Property::Value;
use ALKO::Catalog::Brand;
use ALKO::Catalog::Manufacturer;
use ALKO::Country;

my $category = XML::Simple->new;
my $category = $category->XMLin("$ENV{PWD}/../../../data/i/category.xml", KeyAttr => { category => 'id' });

while( my( $id_categ, $categ ) = each %{$category->{category}} ){
	# Выводим id категории в консоль
	print "$key \n";

	# Новая категория
	ALKO::Catalog::Category->new({
		id      => $id_categ,
		name    => $categ->{name},
		visible => 1,
	})->Save;

	my $catalog = ALKO::Catalog->new;
	my $parent = $catalog->curnode;

	# Добавляем категорию в дерево
	ALKO::Catalog::Category::Graph->new({
		down  => $key,
		sortn => $parent->has_child + 1,
		top   => $ALKO::Catalog::ROOT,
	})->Save;

	# Товары и свойства
	while( my( $key_products, $products) = each %{$categ->{products}}){
		if (ref $products eq 'ARRAY') {
			for (@$products) {
				# Выводим id товара
				print "$_->{id} \n";

				# Добавляем товар
				my $product = ALKO::Catalog::Product->new({
					name    => $_->{name},
					alkoid  => $_->{id},
					visible => 1,
				})->Save;

				# Цена
				ALKO::Catalog::Property::Value->new({
					id_product   => $product->{id},
					id_propgroup => 1,
					n_property   => 1,
					val_dec      => $_->{price} ? $_->{price} : 0,
				})->Save;

				# Литраж
				ALKO::Catalog::Property::Value->new({
					id_product   => $product->{id},
					id_propgroup => 1,
					n_property   => 4,
					val_float    => $_->{litr} ? $_->{litr} : 0,
				})->Save;

				# Алкоголь %
				ALKO::Catalog::Property::Value->new({
					id_product   => $product->{id},
					id_propgroup => 1,
					n_property   => 5,
					val_float    => $_->{alcmin} ? $_->{alcmin} : 0,
				})->Save;

				# Остаток
				ALKO::Catalog::Property::Value->new({
					id_product   => $product->{id},
					id_propgroup => 1,
					n_property   => 8,
					val_int      => $_->{qty} ? $_->{qty} : 0,
				})->Save;

				# Бренд
				my $brend = ALKO::Catalog::Brand->Get(alkoid => $_->{brand}) if  $_->{brand};
				if ($brend) {
					ALKO::Catalog::Property::Value->new({
						id_product   => $product->{id},
						id_propgroup => 1,
						n_property   => 2,
						val_int      => $brend->{id},
					})->Save;
				}

				for my $param (@{$_->{parameters}{parameter}}) {
					# Страна
					if($param->{id} == 1) {
						my $country = ALKO::Country->Get(name => $param->{value});

						$country = ALKO::Country->new({
							name => $param->{value},
						})->Save unless $country;

						ALKO::Catalog::Property::Value->new({
							id_product   => $product->{id},
							id_propgroup => 1,
							n_property   => 7,
							val_int      => $country->{id},
						})->Save;
					}

					# Фасовка
					if($param->{id} == 2) {
						ALKO::Catalog::Property::Value->new({
							id_product   => $product->{id},
							id_propgroup => 1,
							n_property   => 6,
							val_int      => $param->{value},
						})->Save unless ref $param->{value} eq 'HASH';
					}
				}

				# Добавляем товар в категорию
				ALKO::Catalog::Product::Link->new({
					id_category => $id_categ,
					id_product  => $product->{id},
				})->Save;
			}
		} elsif (ref $products eq 'HASH') {
			# Выводим id товара
			print "$products->{id} \n";

			# Добавляем товар
			my $product = ALKO::Catalog::Product->new({
				name    => $products->{name},
				alkoid  => $products->{id},
				visible => 1,
			})->Save;

			# Цена
			ALKO::Catalog::Property::Value->new({
				id_product   => $product->{id},
				id_propgroup => 1,
				n_property   => 1,
				val_dec      => $products->{price} ? $products->{price} : 0,
			})->Save;

			# Литраж
			ALKO::Catalog::Property::Value->new({
				id_product   => $product->{id},
				id_propgroup => 1,
				n_property   => 4,
				val_float    => $products->{litr} ? $products->{litr} : 0,
			})->Save;

			# Алкоголь %
			ALKO::Catalog::Property::Value->new({
				id_product   => $product->{id},
				id_propgroup => 1,
				n_property   => 5,
				val_float    => $products->{alcmin} ? $products->{alcmin} : 0,
			})->Save;

			# Остаток
			ALKO::Catalog::Property::Value->new({
				id_product   => $product->{id},
				id_propgroup => 1,
				n_property   => 8,
				val_int      => $products->{qty} ? $products->{qty} : 0,
			})->Save;

			# Бренд
			my $brend = ALKO::Catalog::Brand->Get(alkoid => $products->{brand})  if  $products->{brand};
			if ($brend) {
				ALKO::Catalog::Property::Value->new({
					id_product   => $product->{id},
					id_propgroup => 1,
					n_property   => 2,
					val_int      => $brend->{id},
				})->Save;
			}

			for my $param (@{$products->{parameters}{parameter}}) {
				# Страна
				if($param->{id} == 1) {
					my $country = ALKO::Country->Get(name => $param->{value});

					$country = ALKO::Country->new({
						name => $param->{value},
					})->Save unless $country;

					ALKO::Catalog::Property::Value->new({
						id_product   => $product->{id},
						id_propgroup => 1,
						n_property   => 7,
						val_int      => $country->{id},
					})->Save;
				}

				# Фасовка
				if($param->{id} == 2) {
					ALKO::Catalog::Property::Value->new({
						id_product   => $product->{id},
						id_propgroup => 1,
						n_property   => 6,
						val_int      => $param->{value},
					})->Save unless ref $param->{value} eq 'HASH';
				}
			}

			# Добавляем товар в категорию
			ALKO::Catalog::Product::Link->new({
				id_category => $id_categ,
				id_product  => $product->{id},
			})->Save;
		}
	}
}

print "END \n";