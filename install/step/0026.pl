#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use WooF::Install ();

my $install = WooF::Install->new(__FILE__);

$install->sql('order_fkeys.sql');
$install->complete(<<MSG);
- Обновлены внешние ключи таблицы заказов
MSG
