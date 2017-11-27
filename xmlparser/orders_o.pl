#!/usr/bin/perl
use strict;

use ALKO::Order;
use XML::Simple;
use WooF::Debug;
use Data::Structure::Util qw( unbless );

debug "START \n";

my $orders_xml = XML::Simple->new;
my $file_path = "$ENV{HOME}/data/o/orders.xml";
my @xml_data;

my $orders->{order} = ALKO::Order->All(alko_sync_status => 0)->List;

for my $order (@{$orders->{order}}) {
	$order->products;
	$order->documents;

	$order->shop;
	$order->{contractor}  = $order->{shop}{net}{official}{alkoid};
	$order->{trade_point} = $order->{shop}{official}{alkoid};

	$order->status;
	$order->{status}   = $order->{status}{name};
	$order->{order_id} = $order->{alkoid};
	$order->{number}   = $order->{num};

	my $products->{product} = $order->{products}{elements};
	for (@{$products->{product}}) {
		$_->{id}  = $_->{product}{alkoid};
		 delete @{$_}{qw(
			id_order
			id_product
			n
			product
		)};
	}
	delete $products->{name};
	$order->{products} = $products;

	# Не выгружать документы со статусом uploaded
	my @documents = grep {
		delete @$_{qw/id_order n/} if $_->{status} ne 'uploaded';
	} @{$order->{documents}{elements}};

	$order->{documents} = {document => \@documents};

	delete @$order{qw(
		id_status
		id_shop
		shop
		id_merchant
		alkoid
		alko_sync_status
		num
	)};
}

# Создаем хэш из объекта
unbless $orders;
for my $order (@{$orders->{order}}){
	delete $order->{STATE};

	for my $product (@{$order->{products}{product}}) {

		delete $product->{STATE};
	}

	for my $document (@{$order->{documents}{document}}) {
		delete $document->{STATE};
	}
};

open my $fh, '>:encoding(utf-8)', $file_path or die "open($file_path): $!";

print $fh "<?xml version='1.0' encoding='UTF-8'?>\n";

$orders_xml->XMLout($orders, OutputFile => $fh, NoAttr => 1, RootName => 'orders' );

close $fh;

debug "END \n";

1;