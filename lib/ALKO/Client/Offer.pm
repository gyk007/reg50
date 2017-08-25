package ALKO::Client::Offer;
use base qw/ WooF::Object::Simple /;

=begin nd
Class: ALKO::Client::Offer
	Индивидуальное предложение.
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	id_shop    - торговая точка
	id_product - товар
	type       - тип скидки; percent - скидка в процентах; rub - рублях
	value      - значение скидки
	ctime      - дата создания
=cut
my %Attribute = (
	id_shop    => undef,
	id_product => undef,
	type       => {mode => 'read'},
	value      => {mode => 'read'},
	ctime      => undef,
);
=begin nd
Method: Attribute ()
	Доступ к хешу с описанием членов класса.
	Может вызываться и как метод экземпляра, и как метод класса.

Returns:
	ссылку на описание членов класса
=cut
sub Attribute { \%Attribute }

=begin nd
Method: Table ( )
	Таблица хранения сущности в базе данных.

Returns:
	Строку 'Offer'.
=cut
sub Table { 'Offer' }

1;