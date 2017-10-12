#!/usr/bin/perl
use strict;

use XML::Simple;
use WooF::Debug;
use LWP::Simple;

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
my $category = $category->XMLin("$ENV{HOME}/data/i/categories.xml", KeyAttr => { category => 'id' });

my $all_product_category = ALKO::Catalog::Category->Get(id => 1);

$all_product_category = ALKO::Catalog::Category->new({
	id      => 1,
	name    => 'Все товары',
	visible => 1,
})->Save unless $all_product_category;

while( my( $id_categ, $categ ) = each %{$category->{category}} ){
	# Выводим id категории в консоль
	print "$id_categ \n";

	# Проверяем на существование категории
	my $is_exist_category = ALKO::Catalog::Category->Get(id => $id_categ);

	# Создаем новую категорию если ее не существует
	unless ($is_exist_category) {
		ALKO::Catalog::Category->new({
			id      => $id_categ,
			name    => $categ->{name},
			visible => 1,
		})->Save;

		my $catalog = ALKO::Catalog->new;
		my $parent  = $catalog->curnode;

		# Добавляем категорию в дерево
		ALKO::Catalog::Category::Graph->new({
			down  => $id_categ,
			sortn => $parent->has_child + 1,
			top   => $ALKO::Catalog::ROOT,
		})->Save;
	}

	# Товары и свойства
	while( my( $key_products, $products) = each %{$categ->{products}}) {
		if (ref $products eq 'ARRAY') {
			for (@$products) {
				# Выводим id товара
				print "$_->{id} \n";

				# Проверяем еслть ли товар
				my $product = ALKO::Catalog::Product->Get(alkoid => $_->{id});
				# Елси есть товара - обновляем
				if ($product) {
					print "UPDATE $_->{id} \n";

					if ($_->{thumbnailSrc}) {
						my ($ext) = $_->{thumbnailSrc} =~ /\.([A-z0-9]+)$/;
						unless ( -f "$ENV{HOME}/www/backend/files/product_img/small/$_->{id}.$ext") {
							getstore($_->{thumbnailSrc}, "$ENV{HOME}/www/backend/files/product_img/small/$_->{id}.$ext");
							$product->img_small("$_->{id}.$ext");
						}
					}

					if ($_->{smallSrc}) {
						my ($ext) = $_->{smallSrc} =~ /\.([A-z0-9]+)$/;
						unless ( -f "$ENV{HOME}/www/backend/files/product_img/medium/$_->{id}.$ext") {
							getstore($_->{smallSrc}, "$ENV{HOME}/www/backend/files/product_img/medium/$_->{id}.$ext");
							$product->img_medium("$_->{id}.$ext");
						}
					}

					if ($_->{largeSrc}) {
						my ($ext) = $_->{largeSrc} =~ /\.([A-z0-9]+)$/;
						unless ( -f "$ENV{HOME}/www/backend/files/product_img/big/$_->{id}.$ext") {
							getstore($_->{largeSrc}, "$ENV{HOME}/www/backend/files/product_img/big/$_->{id}.$ext");
							$product->img_big("$_->{id}.$ext");
						}
					}

					# Обновляем имя
					$product->name($_->{name}) if $product;
					$product->Save;

					# Цена
					my $product_price = ALKO::Catalog::Property::Value->Get(
						id_product   => $product->{id},
						id_propgroup => 1,
						n_property   => 1,
					);
					$product_price->{val_dec} =  $_->{price} ? $_->{price} : 0;
					$product_price->Save;

					# Литраж
					my $product_litr = ALKO::Catalog::Property::Value->Get(
						id_product   => $product->{id},
						id_propgroup => 1,
						n_property   => 4,
					);
					$product_litr->{val_float} =  $_->{litr} ? $_->{litr} : 0;
					$product_litr->Save;

					# Алкоголь %
					my $product_alko = ALKO::Catalog::Property::Value->Get(
						id_product   => $product->{id},
						id_propgroup => 1,
						n_property   => 5,
					);
					$product_alko->{val_float} =  $_->{alcmin} ? $_->{alcmin} : 0;
					$product_alko->Save;

					# Остаток
					my $product_qty = ALKO::Catalog::Property::Value->Get(
						id_product   => $product->{id},
						id_propgroup => 1,
						n_property   => 8,
					);
					$product_qty->{val_int} =  $_->{qty} ? $_->{qty} : 0;
					$product_qty->Save;


					# Бренд и производитель
					my $brend = ALKO::Catalog::Brand->Get(alkoid => $_->{brand}) if  $_->{brand};
					if ($brend) {
						# Бренд
						my $product_brand = ALKO::Catalog::Property::Value->Get(
							id_product   => $product->{id},
							id_propgroup => 1,
							n_property   => 2,
						);
						$product_brand->{val_int} = $brend->{id} if $product_brand;

						$product_brand = ALKO::Catalog::Property::Value->new({
							id_product   => $product->{id},
							id_propgroup => 1,
							n_property   => 2,
							val_int      => $brend->{id},
						}) unless $product_brand;

						$product_brand->Save;

						# Производитель
						my $product_manufacturer = ALKO::Catalog::Property::Value->Get(
							id_product   => $product->{id},
							id_propgroup => 1,
							n_property   => 3,
						);
						$product_manufacturer->{val_int} = $brend->{id_manufacturer} if $product_manufacturer;

						$product_manufacturer = ALKO::Catalog::Property::Value->new({
							id_product   => $product->{id},
							id_propgroup => 1,
							n_property   => 3,
							val_int      => $brend->{id_manufacturer},
						}) unless $product_manufacturer;

						$product_manufacturer->Save;
					}

					for my $param (@{$_->{parameters}{parameter}}) {
						# Страна
						if($param->{id} == 1) {
							my $country = ALKO::Country->Get(name => $param->{value});

							$country = ALKO::Country->new({
								name => $param->{value},
							})->Save unless $country;

							# Страна
							my $product_country = ALKO::Catalog::Property::Value->Get(
								id_product   => $product->{id},
								id_propgroup => 1,
								n_property   => 7,
							);
							$product_country->{val_int} = $country->{id} if $product_country;

							$product_country = ALKO::Catalog::Property::Value->new({
								id_product   => $product->{id},
								id_propgroup => 1,
								n_property   => 7,
								val_int      => $country->{id},
							}) unless $product_country;

							$product_country->Save;
						}

						# Фасовка
						if($param->{id} == 2) {
							# Фасовка
							my $product_pack = ALKO::Catalog::Property::Value->Get(
								id_product   => $product->{id},
								id_propgroup => 1,
								n_property   => 6,
							);

							if (ref $param->{value} ne 'HASH') {
								$product_pack->{val_int} = $param->{value} if $product_pack;

								$product_pack = ALKO::Catalog::Property::Value->new({
									id_product   => $product->{id},
									id_propgroup => 1,
									n_property   => 6,
									val_int      => $param->{value},
								}) unless $product_pack;

								$product_pack->Save;
							}
						}
					}
				}

				# Елси нет товара - добавляем товар
				unless ($product) {
					print "NEW $_->{id} \n";

					$product = ALKO::Catalog::Product->new({
						name    => $_->{name},
						alkoid  => $_->{id},
						visible => 1,
					});

					if ($_->{thumbnailSrc}) {
						my ($ext) = $_->{thumbnailSrc} =~ /\.([A-z0-9]+)$/;
						getstore($_->{thumbnailSrc}, "$ENV{HOME}/www/backend/files/product_img/small/$_->{id}.$ext");
						$product->img_small("$_->{id}.$ext");
					}

					if ($_->{smallSrc}) {
						my ($ext) = $_->{smallSrc} =~ /\.([A-z0-9]+)$/;
						getstore($_->{smallSrc}, "$ENV{HOME}/www/backend/files/product_img/medium/$_->{id}.$ext");
						$product->img_medium("$_->{id}.$ext");
					}

					if ($_->{largeSrc}) {
						my ($ext) = $_->{largeSrc} =~ /\.([A-z0-9]+)$/;
						getstore($_->{largeSrc}, "$ENV{HOME}/www/backend/files/product_img/big/$_->{id}.$ext");
						$product->img_big("$_->{id}.$ext");
					}

					$product->Save;

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

					# Бренд и производитель
					my $brend = ALKO::Catalog::Brand->Get(alkoid => $_->{brand}) if  $_->{brand};
					if ($brend) {
						# Бренд
						ALKO::Catalog::Property::Value->new({
							id_product   => $product->{id},
							id_propgroup => 1,
							n_property   => 2,
							val_int      => $brend->{id},
						})->Save;

						# Производитель
						ALKO::Catalog::Property::Value->new({
							id_product   => $product->{id},
							id_propgroup => 1,
							n_property   => 3,
							val_int      => $brend->{id_manufacturer},
						})->Save if $brend->{id_manufacturer};
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
			}
		} elsif (ref $products eq 'HASH') {
			# Выводим id товара
			print "$products->{id} \n";

			# Проверяем еслть ли товар
			my $product = ALKO::Catalog::Product->Get(alkoid => $products->{id});
			# Елси есть товара - обновляем
			if ($product) {
				print "UPDATE $products->{id} \n";

				if ($products->{thumbnailSrc}) {
					my ($ext) = $products->{thumbnailSrc} =~ /\.([A-z0-9]+)$/;
					unless ( -f "$ENV{HOME}/www/backend/files/product_img/small/$products->{id}.$ext") {
						getstore($products->{thumbnailSrc}, "$ENV{HOME}/www/backend/files/product_img/small/$products->{id}.$ext");
						$product->img_small("$products->{id}.$ext");
					}
				}

				if ($products->{smallSrc}) {
					my ($ext) = $products->{smallSrc} =~ /\.([A-z0-9]+)$/;
					unless ( -f "$ENV{HOME}/www/backend/files/product_img/medium/$products->{id}.$ext") {
						getstore($products->{smallSrc}, "$ENV{HOME}/www/backend/files/product_img/medium/$products->{id}.$ext");
						$product->img_medium("$products->{id}.$ext");
					}
				}

				if ($products->{largeSrc}) {
					my ($ext) = $products->{largeSrc} =~ /\.([A-z0-9]+)$/;
					unless ( -f "$ENV{HOME}/www/backend/files/product_img/big/$products->{id}.$ext") {
						getstore($products->{largeSrc}, "$ENV{HOME}/www/backend/files/product_img/big/$products->{id}.$ext");
						$product->img_big("$products->{id}.$ext");
					}
				}

				# Обновляем имя
				$product->name($_->{name});
				$product->Save;

				# Цена
				my $product_price = ALKO::Catalog::Property::Value->Get(
					id_product   => $product->{id},
					id_propgroup => 1,
					n_property   => 1,
				);
				$product_price->{val_dec} =  $products->{price} ? $products->{price} : 0;
				$product_price->Save;

				# Литраж
				my $product_litr = ALKO::Catalog::Property::Value->Get(
					id_product   => $product->{id},
					id_propgroup => 1,
					n_property   => 4,
				);
				$product_litr->{val_float} =  $products->{litr} ? $products->{litr} : 0;
				$product_litr->Save;

				# Алкоголь %
				my $product_alko = ALKO::Catalog::Property::Value->Get(
					id_product   => $product->{id},
					id_propgroup => 1,
					n_property   => 5,
				);
				$product_alko->{val_float} =  $products->{alcmin} ? $products->{alcmin} : 0;
				$product_alko->Save;

				# Остаток
				my $product_qty = ALKO::Catalog::Property::Value->Get(
					id_product   => $product->{id},
					id_propgroup => 1,
					n_property   => 8,
				);
				$product_qty->{val_int} =  $products->{qty} ? $products->{qty} : 0;
				$product_qty->Save;


				# Бренд и производитель
				my $brend = ALKO::Catalog::Brand->Get(alkoid => $products->{brand}) if  $products->{brand};
				if ($brend) {
					# Бренд
					my $product_brand = ALKO::Catalog::Property::Value->Get(
						id_product   => $product->{id},
						id_propgroup => 1,
						n_property   => 2,
					);
					$product_brand->{val_int} = $brend->{id} if $product_brand;

					$product_brand = ALKO::Catalog::Property::Value->new({
						id_product   => $product->{id},
						id_propgroup => 1,
						n_property   => 2,
						val_int      => $brend->{id},
					}) unless $product_brand;

					$product_brand->Save;

					# Производитель
					my $product_manufacturer = ALKO::Catalog::Property::Value->Get(
						id_product   => $product->{id},
						id_propgroup => 1,
						n_property   => 3,
					);
					$product_manufacturer->{val_int} = $brend->{id_manufacturer} if $product_manufacturer;

					$product_manufacturer = ALKO::Catalog::Property::Value->new({
						id_product   => $product->{id},
						id_propgroup => 1,
						n_property   => 3,
						val_int      => $brend->{id_manufacturer},
					}) unless $product_manufacturer;

					$product_manufacturer->Save;
				}

				for my $param (@{$products->{parameters}{parameter}}) {
					# Страна
					if($param->{id} == 1) {
						my $country = ALKO::Country->Get(name => $param->{value});

						$country = ALKO::Country->new({
							name => $param->{value},
						})->Save unless $country;

						# Страна
						my $product_country = ALKO::Catalog::Property::Value->Get(
							id_product   => $product->{id},
							id_propgroup => 1,
							n_property   => 7,
						);
						$product_country->{val_int} = $country->{id} if $product_country;

						$product_country = ALKO::Catalog::Property::Value->new({
							id_product   => $product->{id},
							id_propgroup => 1,
							n_property   => 7,
							val_int      => $country->{id},
						}) unless $product_country;

						$product_country->Save;
					}

					# Фасовка
					if($param->{id} == 2) {
						my $product_pack = ALKO::Catalog::Property::Value->Get(
							id_product   => $product->{id},
							id_propgroup => 1,
							n_property   => 6,
						);

						if (ref $param->{value} ne 'HASH') {
							$product_pack->{val_int} = $param->{value} if $product_pack;

							$product_pack = ALKO::Catalog::Property::Value->new({
								id_product   => $product->{id},
								id_propgroup => 1,
								n_property   => 6,
								val_int      => $param->{value},
							}) unless $product_pack;

							$product_pack->Save;
						}
					}
				}
			}

			unless ($product) {
				print "NEW $products->{id} \n";
				# Добавляем товар
				$product = ALKO::Catalog::Product->new({
					name    => $products->{name},
					alkoid  => $products->{id},
					visible => 1,
				});

				if ($products->{thumbnailSrc}) {
					my ($ext) = $products->{thumbnailSrc} =~ /\.([A-z0-9]+)$/;
					getstore($products->{thumbnailSrc}, "$ENV{HOME}/www/backend/files/product_img/small/$products->{id}.$ext");
					$product->img_small("$products->{id}.$ext");
				}

				if ($products->{smallSrc}) {
					my ($ext) = $products->{smallSrc} =~ /\.([A-z0-9]+)$/;
					getstore($products->{smallSrc}, "$ENV{HOME}/www/backend/files/product_img/medium/$products->{id}.$ext");
					$product->img_medium("$products->{id}.$ext");
				}

				if ($products->{largeSrc}) {
					my ($ext) = $products->{largeSrc} =~ /\.([A-z0-9]+)$/;
					getstore($products->{largeSrc}, "$ENV{HOME}/www/backend/files/product_img/big/$products->{id}.$ext");
					$product->img_big("$products->{id}.$ext");
				}

				$product->Save;

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

				# Бренд и производитель
				my $brend = ALKO::Catalog::Brand->Get(alkoid => $products->{brand})  if  $products->{brand};
				if ($brend) {
					# Бренд
					ALKO::Catalog::Property::Value->new({
						id_product   => $product->{id},
						id_propgroup => 1,
						n_property   => 2,
						val_int      => $brend->{id},
					})->Save;

					# Производитель
					ALKO::Catalog::Property::Value->new({
						id_product   => $product->{id},
						id_propgroup => 1,
						n_property   => 3,
						val_int      => $brend->{id_manufacturer},
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

		# Добавляем товар в категорию Все товары
		my $prod_in_all_cat = ALKO::Catalog::Product::Link->Get(
			id_category => $all_product_category->id,
			id_product  => $product->id,
		);

		ALKO::Catalog::Product::Link->new({
			id_category => $all_product_category->id,
			id_product  => $product->id,
		})->Save unless $prod_in_all_cat;
	}
}

print "END \n";