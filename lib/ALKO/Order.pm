package ALKO::Order;
use base qw/ WooF::Object::Simple /;

=begin nd
Class: ALKO::Order
	Заказ.
=cut

use strict;
use warnings;

use ALKO::Client::Net;
use ALKO::Client::Shop;
use ALKO::Order::Document;
use ALKO::Order::Product;
use ALKO::Order::Status;


=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	address          - адрес
	alkoid           - ид в системе заказчика
	alko_sync_status - статус синхронизации заказа с системой заказчика (true - синхронизирован, false (default) - не синхронизирован)
	ctime            - дата заказа
	deliver_date     - дата доставки
	deliver_interval - интервал доставки
	deliver_name     - имя водителя
	deliver_phone    - телефон водителя
	documents        - документы, коллекция экземпляров класса <ALKO::Order::Document>
	email            - адрес электронной почты
	id_merchant      - представитель
	id_shop          - магазин
	id_status        - статус
	latch_number     - номер фиксации в ЕГАИС
	name             - имя заказчика
	num              - номер заказ
	phone            - телефон
	price            - цена
	products         - товары, коллекция экземпляров класса <ALKO::Order::Product>
	receivables      - задолженность
	remark           - замечание
	sales_name       - имя торгового представителя Reg50
	sales_phone      - телефон торгового представителя Reg50
	shop             - магазин, экземпляр класса <ALKO::Client::Shop>
	status           - статус, экземпляр класса <ALKO::Order::Status>
	ttn_date         - дата ТТН
	ttn_id           - идентификатор ТТН
	ttn_number       - номер ТТН
=cut
my %Attribute = (
	address          => undef,
	alkoid           => undef,
	alko_sync_status => {mode => 'read/write', default => 0},
	ctime            => undef,
	deliver_date     => undef,
	deliver_interval => undef,
	deliver_name     => undef,
	deliver_phone    => undef,
	documents        => {mode => 'read', type => 'cache'},
	email            => undef,
	id_merchant      => undef,
	id_shop          => undef,
	id_status        => undef,
	latch_number     => undef,
	name             => undef,
	num              => undef,
	phone            => undef,
	price            => undef,
	products         => {mode => 'read', type => 'cache'},
	receivables      => undef,
	remark           => undef,
	sales_name       => undef,
	sales_phone      => undef,
	shop             => {mode => 'read', type => 'cache'},
	status           => {mode => 'read', type => 'cache'},
	ttn_date         => undef,
	ttn_id           => undef,
	ttn_number       => undef,
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
	# Если уже есть данные, то ничего не делаем
	return $self->{documents} if defined $self->{documents};

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
	# Если уже есть данные, то ничего не делаем
	return $self->{products} if defined $self->{products};

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
	# Если уже есть данные, то ничего не делаем
	return $self->{shop} if defined $self->{shop};

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
	# Если уже есть данные, то ничего не делаем
	return $self->{status} if defined $self->{status};

 	$self->{status} = ALKO::Order::Status->Get(id => $self->{id_status});
}

=begin nd
Method: Table ( )
	Таблица хранения сущности в базе данных.

Returns:
	Строку 'orders'.
=cut
sub Table { 'orders' }