#! /usr/bin/perl

use strict;
use warnings;
use utf8;

use WooF::Install;

my $install = WooF::Install->new(__FILE__);

$install->sql('product_img.sql');

$install->complete(<<MSG);
- Добавлена поля для картинок товара
MSG