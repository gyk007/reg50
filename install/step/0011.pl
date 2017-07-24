#! /usr/bin/perl

use strict;
use warnings;
use utf8;

use WooF::Install;

my $install = WooF::Install->new(__FILE__);

$install->sql('main_properties.sql');

$install->complete(<<MSG);
Заведены основные свойства оригинального каталога.
MSG
