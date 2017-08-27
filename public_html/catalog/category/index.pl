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

		$O->{category} = $category->complete_products;
		 
		foreach (@{$category->{extend}{products}{elements}}) {			 
			$_->price($O->{SHOP}{id})
		};

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
