package ALKO::Cart::Pickedup;
use base qw/ WooF::Object::Sequence /;

=begin nd
Class: ALKO::Cart::Pickedup
	Товары в корзине.
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	id_merchant - торговый представитель
	id_product  - товар
	ncart       - номер корзины в рамках одного торгового представителя
	quantity    - количество
	product     - товар, экземпляр класса <ALKO::Catalog::Product>

=cut
my %Attribute = (
	id_merchant => {mode => undef, type => 'key'},
	ncart       => {mode => undef, type => 'key'},
	id_product  => {mode => undef},
	quantity    => {mode => 'read/write'},
	product     => {mode=>'write', type => 'cache'},
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
Method: Table ( )
	Таблица хранения сущности в базе данных.

Returns:
	Строку 'pickedup'.
=cut
sub Table { 'pickedup' }

1;