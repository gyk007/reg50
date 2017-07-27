#! /usr/bin/perl

use strict;
use warnings;
use utf8;

use WooF::Install;

my $install = WooF::Install->new(__FILE__);

$install->sql('client.sql');

$install->complete(<<MSG);
Cоздана таблица клиентов.
MSG

