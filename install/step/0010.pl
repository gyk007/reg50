#! /usr/bin/perl

use strict;
use warnings;
use utf8;

use WooF::Install;

my $install = WooF::Install->new(__FILE__);

$install->sql('category_graph_unique.sql');

$install->complete(<<MSG);
Заменен уникальный индекс в таблице графа категорий.
MSG
