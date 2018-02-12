package ALKO::Client::Shop;
use base qw/ WooF::Object::Simple /;

=begin nd
Class: ALKO::Client::Shop
	Магазин.
=cut

use strict;
use warnings;

use ALKO::Client::Official;
use ALKO::Client::Net;
use ALKO::Client::Merchant;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	id_merchant         - представитель
	id_net              - сеть
	id_official         - реквизиты
	official            - реквизиты, экземпляр класса <ALKO::Client::Official>
	net                 - организация, экземпляр класса <ALKO::Client::Net>
	merchant            - представитель, экземпляр класса <ALKO::Client::Merchant>
	merchant_name       - имя предсавителя (данные нужны для таблицы, так как на таблица на Webix не работает с данными типа net.official.name)
	merchant_phone      - телефон представителя (данные нужны для таблицы, так как на таблица на Webix не работает с данными типа net.official.name)
	merchant_email      - email представителя (данные нужны для таблицы, так как на таблица на Webix не работает с данными типа net.official.name)
	shop_name           - название магазина (данные нужны для таблицы, так как на таблица на Webix не работает с данными типа net.official.name)
	shop_taxreasoncode  - КПП магазина (данные нужны для таблицы, так как на таблица на Webix не работает с данными типа net.official.name)
	shop_regaddress     - адрес магазина (данные нужны для таблицы, так как на таблица на Webix не работает с данными типа net.official.name)
=cut
my %Attribute = (
	id_merchant         => {mode => 'read/write'},
	id_net              => {mode => 'read'},
	id_official         => undef,
	official            => {mode => 'read', type => 'cache'},
	net                 => {mode => 'read', type => 'cache'},
	merchant            => {mode => 'read', type => 'cache'},
	merchant_name       => {type => 'cache'},
	merchant_phone      => {type => 'cache'},
	merchant_email      => {type => 'cache'},
	shop_name           => {type => 'cache'},
	shop_taxreasoncode  => {type => 'cache'},
	shop_regaddress     => {type => 'cache'},
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
Method: net
	Получить данные о сети.

Returns:
	$self->{net}
=cut
sub net {
	my $self = shift;
	# Если уже есть данные, то ничего не делаем
	return $self->{net} if defined $self->{net};

	my $net =  ALKO::Client::Net->Get(id => $self->{id_net});
	$net->official;
	$self->{net} = $net;
}

=begin nd
Method: merchant
	Получить данные о представителе.

Returns:
	$self->{merchant}
=cut
sub merchant {
	my $self = shift;
	# Если уже есть данные, то ничего не делаем
	return $self->{merchant} if defined $self->{merchant};

	my $merchant = ALKO::Client::Merchant->Get(id => $self->{id_merchant});

	$self->{merchant} = $merchant;
	# Это сделано из кривой работы Webix
	$self->{merchant_name}  = $merchant->name  || '-';
	$self->{merchant_phone} = $merchant->phone || '-';
	$self->{merchant_email} = $merchant->email || '-';

	$self->{merchant};
}

=begin nd
Method: official
	Получить данные о магазине.

Returns:
	$self->{official}
=cut
sub official {
	my $self = shift;
	# Если уже есть данные, то ничего не делаем
	return $self->{official} if defined $self->{official};

	my $official = ALKO::Client::Official->Get(id => $self->{id_official});

	$self->{official} = $official;

	# Это сделано из кривой работы Webix
	$self->{shop_name}          = $official->name           || '-';
	$self->{shop_taxreasoncode} = $official->taxreasoncode  || '-';
	$self->{shop_address}       = $official->address        || '-';

	$self->{official};
}

=begin nd
Method: Table ( )
	Таблица хранения сущности в базе данных.

Returns:
	Строку 'shop'.
=cut
sub Table { 'shop' }

1;
