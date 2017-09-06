#!/usr/bin/perl
use strict;

use ALKO::Order;
use ALKO::Catalog::Product;
use ALKO::Order::Status;
use XML::Simple;
use WooF::Debug;


my $orders = XML::Simple->new;
$orders = $orders->XMLin("$ENV{PWD}/../../../data/i/orders.xml", KeyAttr => { order => 'id' });


debug $orders;

while( my( $id, $data ) = each %{$orders->{order}} ){

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
    $order->{deliver_phone}    = $data->{deliver_phone}    if $data->{deliver_phone}    and ref $data->{deliver_phone}    ne 'HASH';
    $order->{sales_name}       = $data->{sales_name}       if $data->{sales_name}       and ref $data->{sales_name}       ne 'HASH';
    $order->{sales_phone}      = $data->{sales_phone}      if $data->{sales_phone}      and ref $data->{sales_phone}      ne 'HASH';
    $order->{alkoid}           = $data->{alkoid}           if $data->{alkoid}           and ref $data->{alkoid}           ne 'HASH';

    $order->Refresh;

    # Обновляем товары
    for (@{$data->{products}{product}}) {
       my $product = ALKO::Catalog::Product->Get(alkoid => $_->{id});

       if($product) {
            my $order_product = ALKO::Order::Product->Get(id_order => $order->id, id_product => $product->id);
            if ($order_product) {
                $order_product->{price} = $_->{price};
                $order_product->{qty}   = $_->{qty};
                $order_product->Refresh;
            } else {
                ALKO::Order::Product->new({
                    id_order    => $order->id,
                    id_product  => $product->id,
                    price       => $_->{price},
                    qty         => $_->{qty},
                })
            }
       } else {
            print "Такого товара не существует\n";
       }
    }
}

print "END \n";