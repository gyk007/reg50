#! /usr/bin/perl

use strict;
use warnings;
use utf8;

use WooF::Install;

my $install = WooF::Install->new(__FILE__);

$install->sql('brand.sql');
$install->sql('propparam.sql');

$install->complete(<<MSG);
Добавлена таблица производителей
Добавлена таблица брендов
Добавлена таблица параметров типов свойств
Добавлена таблица значений параметров типов свойств
MSG
