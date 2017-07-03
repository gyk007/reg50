#! /usr/bin/perl

use strict;
use warnings;
use utf8;

use WooF::Install;

my $install = WooF::Install->new(__FILE__);

$install->sql('category_graph.sql');

$install->complete(<<MSG);
Добавлена таблица дерева категорий
MSG
