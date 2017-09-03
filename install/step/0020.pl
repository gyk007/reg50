#! /usr/bin/perl

use strict;
use warnings;
use utf8;

use WooF::Install;

my $install = WooF::Install->new(__FILE__);

$install->sql('statistic.sql');

$install->complete(<<MSG);
- Добавлены таблицы для статистики
MSG