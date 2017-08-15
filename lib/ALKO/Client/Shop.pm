package ALKO::Client::Shop;
use base qw/ WooF::Object::Simple /;

=begin nd
Class: ALKO::Client::Shop
	Магазин.
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	id_merchant - представитель
	id_net      - сеть
	id_official - реквизиты
=cut
my %Attribute = (
	id_merchant => {mode => undef, type => 'key'},
	id_net      => {mode => undef, type => 'key'},
	id_official => {mode => undef, type => 'key'},
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
	Строку 'shop'.
=cut
sub Table { 'shop' }

1;