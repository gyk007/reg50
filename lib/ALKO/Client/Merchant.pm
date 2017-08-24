package ALKO::Client::Merchant;
use base qw/ WooF::Object::Simple /;

=begin nd
Class: ALKO::Client::Merchant
	Представитель.
=cut

use strict;
use warnings;

use ALKO::Client::Net;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	alkoid   - ид в системе заказчика
	email    - адрес электроной почты
	name     - имя
	password - пароль
	phone    - телефон
	net      - организация, экземпляр класса <ALKO::Client::Net>
=cut
my %Attribute = (
	alkoid   => undef,
	email    => undef,
	name     => undef,
	password => undef,
	phone    => undef,
	net      => {mode => 'read', type => 'cache'},
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

	my $net =  ALKO::Client::Net->Get(id_merchant => $self->{id});
	$net->official;

	$self->{net} = $net;
}

=begin nd
Method: Table ( )
	Таблица хранения сущности в базе данных.

Returns:
	Строку 'merchant'.
=cut
sub Table { 'merchant' }

1;