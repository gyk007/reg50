package ALKO::Catalog::Filter::Arg;
use base qw/ WooF::Object::Simple /;

=begin nd
Class: ALKO::Catalog::Filter::Arg
	Аргументы фильтра, задающие выборку.
	
	Например, 'min' означает, что фильтр устанавливает клиенту минимально существующее
	значение свойства среди всех фигурирующих в выборке товаров.
=cut

use strict;
use warnings;

=begin nd
Variable: my %Attribute
	Члены класса:
	description - описание для админа
	name        - короткое имя для ссылки из кода
	value       - начальное значение для конкретной категории
=cut
my %Attribute = (
	description => undef,
	name        => {mode => 'read'},
	value       => {mode => 'read/write', type => 'cache'},
);

=begin nd
Method: Attribute ( )
	Доступ к хешу с описанием членов класса.
	
	Может вызываться и как метод экземпляра, и как метод класса.
	Наследует члены класса родителей.

Returns:
	ссылку на описание членов класса
=cut
sub Attribute { +{ %{+shift->SUPER::Attribute}, %Attribute} }

sub Table { 'filterarg' }

1;
