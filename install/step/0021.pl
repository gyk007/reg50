#! /usr/bin/perl

use strict;
use warnings;
use utf8;

use WooF::Install;

my $install = WooF::Install->new(__FILE__);

$install->sql('order_sync.sql');

$install->complete(<<MSG);
- Добавлено поле alko_sync_status в таблицу orders
MSG