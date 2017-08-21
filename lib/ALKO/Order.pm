package ALKO::Order;
use base qw/ WooF::Object::Simple /;

=begin nd
Class: ALKO::Order
	Заказ.
=cut

use strict;
use warnings;

use ALKO::Order::Document;
use ALKO::Order::Product;
use ALKO::Order::Status;
use ALKO::Client::Shop;
use ALKO::Client::Net;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	num              - номер заказ
	id_status        - статус
	receivables      - задолженность
	phone            - телефон
	address          - адрес
	name             - имя заказчика
	price            - цена
	ctime            - дата заказа
	remark           - замечание
	id_net           - организация
	id_shop          - магазин
	latch_number     - номер фиксации в ЕГАИС
	ttn_id           - идентификатор ТТН
	ttn_number       - номер ТТН
	ttn_date         - дата ТТН
	deliver_date     - дата доставки
	deliver_interval - интервал доставки
	deliver_name     - имя водителя
	deliver_phone    - телефон водителя
	sales_name       - имя торгового представителя Reg50
	sales_phone      - телефон торгового представителя Reg50
	products         - продукты, массив объектов класса <ALKO::Order::Product>
	documents        - документы, массив объектов класса <ALKO::Order::Document>
=cut
my %Attribute = (
	num              => {mode => undef},
	id_status        => {mode => undef},
	receivables      => {mode => undef},
	phone            => {mode => undef},
	address          => {mode => undef},
	name             => {mode => undef},
	ctime            => {mode => undef},
	price            => {mode => undef},
	remark           => {mode => undef},
	id_shop          => {mode => undef},
	id_merchant      => {mode => undef},
	latch_number     => {mode => undef},
	ttn_id           => {mode => undef},
	ttn_number       => {mode => undef},
	ttn_date         => {mode => undef},
	deliver_date     => {mode => undef},
	deliver_interval => {mode => undef},
	deliver_name     => {mode => undef},
	deliver_phone    => {mode => undef},
	sales_name       => {mode => undef},
	sales_phone	     => {mode => undef},
	products         => {mode => 'read', type => 'cache'},
	documents        => {mode => 'read', type => 'cache'},
	status           => {mode => 'read', type => 'cache'},
	shop             => {mode => 'read', type => 'cache'},
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
Method: documents
	получить документы.
Returns:
	$self->{documents}
=cut
sub documents {
	my $self = shift;
	$self->{documents} = ALKO::Order::Document->All(id_order => $self->{id});
}

=begin nd
Method: products
	получить продукты.
Returns:
	$self->{products}
=cut
sub products {
	my $self = shift;
 	my $products =  ALKO::Order::Product->All(id_order => $self->{id});

 	for (@{$products->List}) {
 		$_->product;
 	}

	$self->{products} = $products;
}

=begin nd
Method: shop
	получить данные торговой точки.
Returns:
	$self->{shop}
=cut
sub shop {
	my $self = shift;
 	my $shop = ALKO::Client::Shop->Get(id => $self->{id_shop});
 	$shop->official;
 	$shop->net;
 	$self->{shop} = $shop;
}

=begin nd
Method: status
	получить статус.
Returns:
	$self->{status}
=cut
sub status {
	my $self = shift;
 	$self->{status} = ALKO::Order::Status->Get(id => $self->{id_status});
}

=begin nd
Method: Table ( )
	Таблица хранения сущности в базе данных.

Returns:
	Строку 'orders'.
=cut
sub Table { 'orders' }