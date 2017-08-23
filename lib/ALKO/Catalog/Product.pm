package ALKO::Catalog::Product;
use base qw/ WooF::Object::Simple /;

=begin nd
Class: ALKO::Catalog::Product
	Товар как единица презентации в каталоге, в противовес единице поставки.
=cut

use strict;
use warnings;

use ALKO::Catalog::Property;
use ALKO::Catalog::Property::Value;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	alkoid         - ид в системе заказчика
	description    - полное описание
	face           - наименование, выводимое в каталоге
	face_effective - наименование в каталоге, переопределенное категорией
	name           - наименование
	properties     - значения свойств; разбиты по группам
	price          - цена
	visible        - видимость товара в каталоге для покупателя
=cut
my %Attribute = (
	alkoid         => undef,
	description    => undef,
	face           => undef,
	face_effective => {type => 'cache'},
	name           => undef,
	properties     => {mode => 'read/write', type => 'cache'},
	price          => {type => 'cache'},
	visible        => undef,
);

=begin nd
Method: Attribute ()
	Доступ к хешу с описанием членов класса.

	Может вызываться и как метод экземпляра, и как метод класса.
	Наследует члены класса родителей.

Returns:
	ссылку на описание членов класса
=cut
sub Attribute { +{ %{+shift->SUPER::Attribute}, %Attribute} }

=begin nd
Method: price
	Получить цену
Returns:
	цена в рублях - если установлена
	undef         - в противном случае
=cut
sub price  {
	my  $self = shift;

	# Если уже есть цена, то ничего не делаем
	return $self->{price} if defined $self->{price};

	my $prop     = ALKO::Catalog::Property->Get(const => 'price');
	my $prop_val = ALKO::Catalog::Property::Value->Get(n_property => $prop->{n}, id_propgroup => $prop->{id_propgroup}, id_product => $self->{id});

	$self->{price} = $prop_val->val_dec if defined $prop_val;
}

=begin nd
Method: Table ( )
	Таблица хранения сущности в базе данных.

Returns:
	Строку 'product'.
=cut
sub Table { 'product' }

1;
