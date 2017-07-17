#! /usr/bin/perl

use strict;
use warnings;
use utf8;

use WooF::Install;

my $install = WooF::Install->new(__FILE__);

$install->sql('typetree.sql');
$install->sql('proptypes_init.sql');

$install->complete(<<MSG);
Все имевшиеся свойства со всеми значениями уничтожены!

Созданы таблицы для матрицы выбора прохода по дереву типов свойств:
- proptype_graph
- matrixunit
- unitvalue
- matrix
- matrixnode

Созданы типы свойств Целое и Выбор из таблицы.
MSG
