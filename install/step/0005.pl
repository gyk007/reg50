#! /usr/bin/perl

use strict;
use warnings;
use utf8;

use WooF::Install;

my $install = WooF::Install->new(__FILE__);

$install->sql('propgroup.sql');

$install->complete(<<MSG);
Добавлена таблица групп свойств
Добавлена таблица распределения групп свойств по категориям
MSG
