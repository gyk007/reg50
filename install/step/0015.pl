#! /usr/bin/perl

use strict;
use warnings;
use utf8;

use WooF::Install;

my $install = WooF::Install->new(__FILE__);

$install->sql('cart.sql');

$install->complete(<<MSG);
Созданы таблицы :
- cart     - таблица корзин
- pickedup - таблица продуктов в корзине
MSG