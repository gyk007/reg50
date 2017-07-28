#! /usr/bin/perl

use strict;
use warnings;
use utf8;

use WooF::Install;

my $install = WooF::Install->new(__FILE__);

$install->sql('filter.sql');

$install->complete(<<MSG);
Созданы таблицы для фильтров.
Заведен фильтр для Price.
MSG
