package ALKO::Catalog::Product;
use base qw/ WooF::Object::Simple /;

=begin nd
Class: ALKO::Catalog::Product
	Товар как единица презентации в каталоге, в противовес единице поставки.
=cut

use strict;
use warnings;
use WooF::Debug;
use ALKO::Catalog::Property;
use ALKO::Catalog::Property::Value;
use ALKO::Catalog::Product::Link;
use ALKO::Client::Offer;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	alkoid         - ид в системе заказчика
	description    - полное описание
	face           - наименование, выводимое в каталоге
	face_effective - наименование в каталоге, переопределенное категорией
	link           - список категорий, экземпляр класса <ALKO::Catalog::Product::Link>
	name           - наименование
	properties     - значения свойств; разбиты по группам
	price          - цена
	offer          - скидка
	offer_type     - тип скидки
	visible        - видимость товара в каталоге для покупателя
=cut
my %Attribute = (
	alkoid         => undef,
	description    => undef,
	face           => undef,
	face_effective => {type => 'cache'},
	link           => {type => 'cache'},
	name           => undef,
	properties     => {mode => 'read/write', type => 'cache'},
	price          => {type => 'cache'},
	offer          => {type => 'cache'},
	offer_type     => {type => 'cache'},
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
Method: price (id_shop)
	Получить цену
Returns:
	цена в рублях - если установлена
	undef         - в противном случае
=cut
sub price  {
	my  ($self, $id_shop) = @_;

	# Если уже есть цена, то ничего не делаем
	return $self->{price} if defined $self->{price};	 
	# Ищем скидку
	my $offer;
	if ($id_shop) {
		my $offers = ALKO::Client::Offer->All(id_shop => $id_shop, id_product => $self->id, SORT => ['ctime'])->List;		 
		if ($offers) {
			$offer = pop @$offers;
		}
	}

	# Цена товара
	my $prop     = ALKO::Catalog::Property->Get(const => 'price');
	my $prop_val = ALKO::Catalog::Property::Value->Get(n_property => $prop->{n}, id_propgroup => $prop->{id_propgroup}, id_product => $self->{id});

	my $price = $prop_val->val_dec if defined $prop_val;

	if ($offer) {
		if ($offer->type eq 'percent') {			 
			$self->{offer} = $offer->value;
			$self->{offer_type} = $offer->type;			 
			my $percent_price = 100 + $offer->value;
			$price *= ($percent_price / 100);			 
		} elsif ($offer->type eq 'rub') {
			$self->{offer} = $offer->value;
			$self->{offer_type} = $offer->type;
			$price += $offer->value;
		}
	}
	
	$self->{price} = $price if defined $price;
}

=begin nd
Method: link
	Получить цену
Returns:
	список категорий - если продукт принадлежит категории
=cut
sub link  {
	my  $self = shift;

	# Если уже есть цена, то ничего не делаем
	return $self->{link} if defined $self->{link};

	$self->{link} = ALKO::Catalog::Product::Link->All(id_product => $self->{id})->List;
}

=begin nd
Method: Table ( )
	Таблица хранения сущности в базе данных.

Returns:
	Строку 'product'.
=cut
sub Table { 'product' }

1;
