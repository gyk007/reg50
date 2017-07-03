#! /usr/bin/perl
#
# Категория дерева каталога
#

use strict;
use warnings;

use WooF::Server;
use ALKO::Catalog::Category;

my $Server = WooF::Server->new(output_t => 'JSON');

# Определенная категория
# URL: /catalog/category?id=125
$Server->add_handler(ITEM => {
	input => {
		allow => ['id'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		$O->{category} = ALKO::Catalog::Category->new($I->{id});

		OK;
	},
});

# Список катагорий
# URL: /catalog/category
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
	
	return ['ITEM'] if $S->I->{id};
	
	['LIST'];
});

$Server->listen;
