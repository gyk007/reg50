package ALKO::Order::Status;
use base qw/ WooF::Object::Simple /;

=begin nd
Class: ALKO::Order::Product
	Товар в заказе.
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	name        - имя статуса
	description - описние
=cut
my %Attribute = (
	name        => undef,
	description => undef,
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

=begin nd
Method: Table ( )
	Таблица хранения сущности в базе данных.

Returns:
	Строку 'order_status'.
=cut
sub Table { 'order_status' }

1;