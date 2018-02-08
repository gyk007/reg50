#! /usr/bin/perl
#
# Новости.
# В зависимости от входных параметров меняется состав вывода.
#

use strict;
use warnings;

use WooF::Server;

my $Server = WooF::Server->new(output_t => 'JSON');

# Создаем новость
#
# POST
# URL: /news/?
#   action           = create
#   news.title       = 20
#   news.text = 2
#
$Server->add_handler(CREATE_NEWS => {
	input => {
		allow => [
			'action',
			news => [qw/ title, text, ctime /],
		],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $catalog = $S->O->{catalog};

		$catalog->link_products;
		$catalog->link_propgroups;

		$S->O->{catalog} = $catalog->print;

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
