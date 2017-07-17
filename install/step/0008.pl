#! /usr/bin/perl

use strict;
use warnings;
use utf8;

use WooF::Install;

my $install = WooF::Install->new(__FILE__);

$install->sql('category_priveleges.sql');

$install->complete(<<MSG);
Обычному юзеру даны права на удаление из таблиц
- категорий
- привязки категорий к дереву
MSG
