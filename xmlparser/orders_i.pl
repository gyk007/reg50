#!/usr/bin/perl
use strict;
use File::Copy;
use IO::File;
use Encode;
use utf8;

use ALKO::Order;
use ALKO::Catalog::Product;
use ALKO::Order::Status;
use ALKO::Order::Document;
use XML::Simple;
use WooF::Error;
use WooF::Debug;
use FindBin;

debug "START \n";

my $orders = XML::Simple->new;
$orders = $orders->XMLin("$ENV{HOME}/data/i/orders.xml", KeyAttr => { order => 'id' });

while( my( $id, $data ) = each %{$orders->{order}} ){
    unless ($id =~ /^\d+$/) {
        debug "ORDER ID: $id IS NOT INT";
        next;
    }

    my $order  = ALKO::Order->Get(id => $id)                       or die "NOSUCH: no such order(id => $id)";
    my $status = ALKO::Order::Status->Get(name => $data->{status}) or die "NOSUCH: no such status(name =>  $data->{status})";

    $order->{id_status} = $status->id;

    $order->{num}              = $data->{number}           if $data->{number}           and ref $data->{number}           ne 'HASH';
    $order->{receivables}      = $data->{receivables}      if $data->{receivables}      and ref $data->{receivables}      ne 'HASH';
    $order->{phone}            = $data->{phone}            if $data->{phone}            and ref $data->{phone}            ne 'HASH';
    $order->{email}            = $data->{email}            if $data->{email}            and ref $data->{email}            ne 'HASH';
    $order->{address}          = $data->{address}          if $data->{address}          and ref $data->{address}          ne 'HASH';
    $order->{price}            = $data->{price}            if $data->{price}            and ref $data->{price}            ne 'HASH';
    $order->{name}             = $data->{name}             if $data->{name}             and ref $data->{name}             ne 'HASH';
    $order->{remark}           = $data->{remark}           if $data->{remark}           and ref $data->{remark}           ne 'HASH';
    $order->{latch_number}     = $data->{latch_number}     if $data->{latch_number}     and ref $data->{latch_number}     ne 'HASH';
    $order->{ttn_id}           = $data->{ttn_id}           if $data->{ttn_id}           and ref $data->{ttn_id}           ne 'HASH';
    $order->{ttn_number}       = $data->{ttn_number}       if $data->{ttn_number}       and ref $data->{ttn_number}       ne 'HASH';
    $order->{ttn_date}         = $data->{ttn_date}         if $data->{ttn_date}         and ref $data->{ttn_date}         ne 'HASH';
    $order->{deliver_date}     = $data->{deliver_date}     if $data->{deliver_date}     and ref $data->{deliver_date}     ne 'HASH';
    $order->{deliver_interval} = $data->{deliver_interval} if $data->{deliver_interval} and ref $data->{deliver_interval} ne 'HASH';
    $order->{deliver_name}     = $data->{deliver_name}     if $data->{deliver_name}     and ref $data->{deliver_name}     ne 'HASH';
    $order->{deliver_phone}    = $data->{delive_phone}     if $data->{delive_phone}     and ref $data->{delive_phone}     ne 'HASH';
    $order->{sales_name}       = $data->{sales_name}       if $data->{sales_name}       and ref $data->{sales_name}       ne 'HASH';
    $order->{sales_phone}      = $data->{sales_phone}      if $data->{sales_phone}      and ref $data->{sales_phone}      ne 'HASH';
    $order->{alkoid}           = $data->{order_id}         if $data->{order_id}         and ref $data->{order_id}         ne 'HASH';
    $order->alko_sync_status(1);

    $order->Refresh;

    next unless all_right;

    my $order_product = ALKO::Order::Product->All(id_order => $order->id);
    # Удалеяем все продукты
    if ($order_product) {
	   $_->Remove for $order_product->List;
    }

    # Добавляем товары
    if ($data->{products}{product} and ref $data->{products}{product} eq 'HASH') {
	   $data->{products}{product} = [$data->{products}{product}];
    }

    if ($data->{products}{product}) {
	for (@{$data->{products}{product}}) {
	    my $product = ALKO::Catalog::Product->Get(alkoid => $_->{id});
	    if ($product) {
        	my $prd = ALKO::Order::Product->new({
            	id_order    => $order->id,
            	id_product  => $product->id,
            	price       => $_->{price},
            	qty         => $_->{qty},
        	})->Save;
	    } else {
    	    debug "PRODUCT ID = $_->{id} NOT EXIST\n";
	    }
	}
    }

}

my @file_name;
# Открываем папку с файлами
opendir DIR, "$ENV{HOME}/data/i/documents/" or die $!;
while(my $file = readdir DIR) {
    push (@file_name, $file) if ($file ne '..' and $file ne '.');
}
closedir DIR;

for my $name (@file_name){
    utf8::decode($name);

    my ($name_doc, $number_and_ext)  = split('_', $name);
    my ($number, $ext)               = split(/\./, $number_and_ext);

    my $order = ALKO::Order->Get(num => $number);

   # НАЗВАНИЕ ДОКУМЕНТОВ В БАЗЕ:
   # - ТТН
   # - ТОРГ-12
   # - Cчет-фактура
   # - Справки ТТН
   # - Сертификаты и удостоверения качества

   if ($order) {
        my $name_in_db;
        $name_in_db = 'Cчет-фактура' if $name_doc eq 'СчетФактура';
        $name_in_db = 'ТОРГ-12'      if $name_doc eq 'Торг-12';
	    $name_in_db = 'ТТН'          if $name_doc eq 'ТТН';

        my $document = ALKO::Order::Document->Get(id_order => $order->id, name => $name_in_db);

        if ($document) {
            $document->{file_name} = $name;
            $document->{status}    = 'uploaded';
            $document->Refresh;
        } else {
            $document = ALKO::Order::Document->new({
                id_order  => $order->id,
                name      => $name_in_db,
                status    => 'uploaded',
                file_name => $name,
            })->Save;
        }
        # Копируем файлы
        copy "$ENV{HOME}/data/i/documents/$name", $FindBin::Bin . "/../files/documents/$name";

   } else {
        debug "ORDER NOT EXIST \n";
   }

};

debug "END \n";