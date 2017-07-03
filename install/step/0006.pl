#! /usr/bin/perl

use strict;
use warnings;
use utf8;

use WooF::Install;

my $install = WooF::Install->new(__FILE__);

$install->sql('property.sql');

$install->complete(<<MSG);
Добавлена таблица свойств
Добавлена таблица распределения свойств по группам
Добавлена таблица фактических значений свойств
MSG
