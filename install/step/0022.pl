#! /usr/bin/perl

use strict;
use warnings;
use utf8;

use WooF::Install;

my $install = WooF::Install->new(__FILE__);

$install->sql('propdata.sql');

$install->complete(<<MSG);
- Добавлена таблица идентификационных данных для движка свойств
MSG