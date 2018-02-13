#! /usr/bin/perl

use strict;
use warnings;
use utf8;

use WooF::Install;

my $install = WooF::Install->new(__FILE__);

$install->sql('news_tag.sql');

$install->complete(<<MSG);
- Добавил теги для новостей
MSG