package ALKO::Client::Net;
use base qw/ WooF::Object::Simple /;

=begin nd
Class: ALKO::Client::Net
	Сеть магазинов.
=cut

use strict;
use warnings;

use ALKO::Client::Official;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	id_official    - реквизиты
	id_merchant    - представитель
	official       - реквизиты, экземпляр класса <ALKO::Client::Official>
	merchant       - представитель сети экземпляр класса <ALKO::Client::Merchant>
	merchant_name  - имя предсавителя (данные нужны для таблицы, так как на таблица на Webix не работает с данными типа net.official.name)
	merchant_phone - телефон представителя (данные нужны для таблицы, так как на таблица на Webix не работает с данными типа net.official.name)
	net_name       - название сети (данные нужны для таблицы, так как на таблица на Webix не работает с данными типа net.official.name)
	net_taxcode    - ИНН сети (данные нужны для таблицы, так как на таблица на Webix не работает с данными типа net.official.name)
=cut
my %Attribute = (
	id_official    => undef,
	id_merchant    => {mode => 'read'},
	official       => {mode => 'read', type => 'cache'},
	merchant       => {mode => 'read', type => 'cache'},
	merchant_name  => {type => 'cache'},
	merchant_phone => {type => 'cache'},
	net_name       => {type => 'cache'},
	net_taxcode    => {type => 'cache'},
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
Method: official
	Получить данные о магазине.
Parameters:
	$official  - экземпляр класса <ALKO::Client::Official>

Returns:
	$self->{official}
=cut
sub official {
	my ($self,  $official)  = @_;
	# Если уже есть данные, то ничего не делаем
	return $self->{official} if defined $self->{official};

	$official = ALKO::Client::Official->Get(id => $self->{id_official}) unless $official;

	$self->{official}    = $official;
	# Это сделано из кривой работы Webix
	$self->{net_name}    = $official->name    ? $official->name    : '-';
	$self->{net_taxcode} = $official->taxcode ? $official->taxcode : '-';

	$self->{official};
}

=begin nd
Method: merchant
	Получить данные о merchant.
Parameters:
	$merchant  - экземпляр класса <ALKO::Client::Merchant>

Returns:
	$self->{merchant}
=cut
sub merchant {
	my ($self,  $merchant)  = @_;
	# Если уже есть данные, то ничего не делаем
	return $self->{merchant} if defined $self->{merchant};

	$merchant = ALKO::Client::Merchant->Get(id => $self->{id_merchant}) unless $merchant;

	$self->{merchant}       = $merchant;
	# Это сделано из кривой работы Webix
	$self->{merchant_name}  = $merchant->name  ? $merchant->name  : '-';
	$self->{merchant_phone} = $merchant->phone ? $merchant->phone : '-';

	$self->{merchant};
}

=begin nd
Method: Table ( )
	Таблица хранения сущности в базе данных.

Returns:
	Строку 'net'.
=cut
sub Table { 'net' }

1;