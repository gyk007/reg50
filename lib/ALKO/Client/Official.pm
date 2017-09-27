package ALKO::Client::Official;
use base qw/ WooF::Object::Simple /;

=begin nd
Class: ALKO::Client::Official
	Реквизиты.
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

Члены класса:
	account       - номер расчетного счета
	address       - фактический адрес
	alkoid        - ид в системе заказчика
	bank          - наименование банка
	bank_account  - номер корреспондентского счета
	bik           - БИК
	email         - адрес электронной почты
	id_file       - логотип
	name          - название компании
	person        - директор
	phone         - телефон
	regaddress    - юридический адрес
	regcode       - ОГРН
	taxcode       - ИНН
	taxreasoncode - КПП

=cut
my %Attribute = (
	account       => undef,
	address       => undef,
	alkoid        => undef,
	bank          => undef,
	bank_account  => undef,
	bik           => undef,
	email         => undef,
	id_file       => undef,
	name          => {mode => 'read'},
	person        => undef,
	phone         => undef,
	regaddress    => undef,
	regcode       => undef,
	taxcode       => {mode => 'read'},
	taxreasoncode => undef,
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
	Строку 'Official'.
=cut
sub Table { 'Official' }

1;