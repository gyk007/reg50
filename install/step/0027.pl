#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use WooF::Install ();

my $install = WooF::Install->new(__FILE__);

$install->sql('v_shop.sql');
$install->complete(<<MSG);
- Представление для получения информации о магазине
MSG
