package ALKO::Client::Merchant;
use base qw/ WooF::Object::Simple /;

=begin nd
Class: ALKO::Client::Merchant
	Представитель.
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	alkoid   - ид в системе заказчика
	email    - адрес электроной почты
	name     - имя
	password - пароль
	phone    - телефон
=cut
my %Attribute = (
	alkoid   => undef,
	email    => undef,
	name     => undef,
	password => undef,
	phone    => undef,
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
	Строку 'merchant'.
=cut
sub Table { 'merchant' }

1;