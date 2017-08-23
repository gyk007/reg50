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
	id_file       - логотип
	name          - название компании
	person        - директор
	address       - фактический адрес
	regaddress    - юридический адрес
	phone         - телефон
	email         - адрес электронной почты
	bank          - наименование банка
	account       - номер расчетного счета
	bank_account  - номер корреспондентского счета
	bik           - БИК
	taxcode       - ИНН
	taxreasoncode - КПП
	regcode       - ОГРН
	alkoid        - ид в системе заказчика
=cut
my %Attribute = (
	id_file       => {type => 'key'},
	name          => undef,
	person        => undef,
	address       => undef,
	regaddress    => undef,
	phone         => undef,
	email         => undef,
	bank          => undef,
	account       => undef,
	bank_account  => undef,
	bik           => undef,
	taxcode       => undef,
	taxreasoncode => undef,
	regcode       => undef,
	alkoid        => undef,
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