package ALKO::Order::Document;
use base qw/ WooF::Object::Simple /;

=begin nd
Class: ALKO::Order::Document
	Документ в заказе.
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	id_order  - заказ
	name      - имя документа
	status    - статус документа
	file_name - имя файла
=cut
my %Attribute = (
	id_order  => {mode => undef},
	name      => {mode => undef},
	status    => {mode => undef},
	file_name => {mode => undef},
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
	Строку 'file_name'.
=cut
sub Table { 'file_name' }

1;