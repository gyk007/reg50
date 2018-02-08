#! /usr/bin/perl

use strict;
use warnings;
use utf8;

use WooF::Install;

my $install = WooF::Install->new(__FILE__);

$install->sql('news.sql');

$install->complete(<<MSG);
- Добавлены таблица новости и таблица связи новости и пердставителя
MSG