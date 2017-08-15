package ALKO::Client::Net;
use base qw/ WooF::Object::Simple /;

=begin nd
Class: ALKO::Client::Net
	Сеть магазинов.
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	id_official - реквизиты, экземпляр класса <ALKO::Client::Official>
	id_merchant   представитель, экземпляр класса <ALKO::Client::Merchant>
=cut
my %Attribute = (
	id_official => {mode => undef, type => 'key'},
	id_merchant => {mode => undef, type => 'key'},
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
	Строку 'net'.
=cut
sub Table { 'net' }

1;