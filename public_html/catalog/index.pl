#! /usr/bin/perl
#
# Дерево категорий.
# В зависимости от входных параметров меняется состав вывода.
#

use strict;
use warnings;

use ALKO::Server;
use ALKO::Catalog;
use ALKO::Catalog::Category;

my $Server = ALKO::Server->new(output_t => 'JSON');

# Дерево категорий без товара
# URL: /catalog/
$Server->add_handler(CATEGORIES => {
	input => {
		allow => [qw/ products /],
	},
	call => sub {
		my $S = shift;

		my $catalog = ALKO::Catalog->new;

		$S->O->{catalog} = exists $S->I->{products} ? $catalog : $catalog->print;

		OK;
	},
});

# Дерево категорий с товарами в каждой категории
# URL: /catalog/?products=all
$Server->add_handler(PRODUCTS => {
	input => {
		allow => [qw/ products /],
	},
	call => sub {
		my $S = shift;

		my $catalog = $S->O->{catalog};

		$catalog->link_products;
		$catalog->link_propgroups;

		$S->O->{catalog} = $catalog->print;

		OK;
	},
});

# Вывод указанной категории со всеми товарами и свойствами со значениями
# URL: /catalog/?category=25
$Server->add_handler(CATEGORY => {
	input => {
		allow => [qw/ category /],
	},
	call => sub {
		my $S = shift;
		my $I = $S->I;
		my $id = $I->{category};

		my $category = ALKO::Catalog::Category->Get(id => $id, EXPAND => [qw/ products propgroups /]) or return $S->fail("OBJECT: No such category id='$id'");

		$category->complete_products;


		$S->O->{category} = $category;

		OK;
	},
});

$Server->dispatcher(sub {
	my $S = shift;
	my $I = $S->I;

	return [qw/ CATEGORY /]            if exists $I->{category};
	return [qw/ CATEGORIES PRODUCTS /] if exists $I->{products};

	return [qw/ CATEGORIES /];
});

$Server->listen;
