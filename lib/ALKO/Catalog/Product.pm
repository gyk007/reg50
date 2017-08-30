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
Method: price (id_shop, $offers, $price)
	Получить цену
Parameters:
	$id_shop  - ид торговой точки
	$offers   - список скидок массив или хэш экземпляров класса <ALKO::Client::Official>
	$price    - стоимость товара
Returns:
	цена в рублях - если установлена
	undef         - в противном случае
=cut
sub price  {
	my  ($self, $id_shop, $offers, $price) = @_;
	# Если уже есть цена, то ничего не делаем
	return $self->{price} if defined $self->{price};

	# Ищем скидку если мы ее не передали
	my $offer;
	if ($id_shop and !$offers) {
		$offers = ALKO::Client::Offer->All(id_shop => $id_shop, id_product => $self->id, SORT => ['ctime'])->List;
	}

	# Если есть скидки, берем последнюю
	if($offers) {
		$offer = pop @$offers if ref $offers eq 'ARRAY';
		$offer = $offers      if ref $offers eq 'HASH';
	}

	# Цена товара, ищем если ее не передали
	unless ($price) {
		my $prop     = ALKO::Catalog::Property->Get(const => 'price');
		my $prop_val = ALKO::Catalog::Property::Value->Get(n_property => $prop->{n}, id_propgroup => $prop->{id_propgroup}, id_product => $self->{id});
		$price = $prop_val->val_dec if defined $prop_val;
	}

	# Расчитываем цену с учетом скидки
	if ($offer) {
		if ($offer->type eq 'percent') {
			$self->{offer}      = $offer->value;
			$self->{offer_type} = $offer->type;
			my $percent_price   = 100 + $offer->value;
			$price *= ($percent_price / 100);
		} elsif ($offer->type eq 'rub') {
			$self->{offer}      = $offer->value;
			$self->{offer_type} = $offer->type;
			$price             += $offer->value;
		}
	}

	$self->{price} = $price if defined $price;
}

=begin nd
Method: link($links)
	Получить список категорий в которых находится данный товар
Parameters:
	$links  - категории в которых находится продукт, массив или хэш экземпляров класса <ALKO::Catalog::Product::Link>
Returns:
	список категорий - если продукт принадлежит категории
=cut
sub link  {
	my  ($self, $links) = @_;

	# Если уже есть данные, то ничего не делаем
	return $self->{link} if defined $self->{link};

	$self->{link} = ALKO::Catalog::Product::Link->All(id_product => $self->{id})->List unless $links;
	$self->{link} = $links if $links;

	$self->{link}
}

=begin nd
Method: Table ( )
	Таблица хранения сущности в базе данных.

Returns:
	Строку 'product'.
=cut
sub Table { 'product' }

1;
