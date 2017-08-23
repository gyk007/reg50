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
	id_official - реквизиты
	id_merchant - представитель
	official    - реквизиты, объект класса <ALKO::Client::Official>
=cut
my %Attribute = (
	id_official => undef,
	id_merchant => undef,
	official    => {mode => 'read', type => 'cache'},
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

Returns:
	$self->{official}
=cut
sub official {
	my $self = shift;
	# Если уже есть данные, то ничего не делаем
	return $self->{official} if defined $self->{official};

	$self->{official} = ALKO::Client::Official->Get(id => $self->{id_official});
}

=begin nd
Method: Table ( )
	Таблица хранения сущности в базе данных.

Returns:
	Строку 'net'.
=cut
sub Table { 'net' }

1;