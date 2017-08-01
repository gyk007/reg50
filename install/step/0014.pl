#! /usr/bin/perl

use strict;
use warnings;
use utf8;

use WooF::Install;

my $install = WooF::Install->new(__FILE__);

$install->sql('merchant.sql');

$install->complete(<<MSG);
Созданы таблицы :
- merchant - таблица представителей
- net      - таблица сетей
- shop     - таблица торговых точек
- file     - таблица файлов
- official - таблица реквизитов
MSG