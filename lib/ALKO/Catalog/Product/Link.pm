package ALKO::Catalog::Product::Link;
use base qw/ WooF::Object /;

=begin nd
Class: ALKO::Catalog::Product::Link
	Размещение товаров по категориям каталога.
	
	Одна категория может содержать несколько товаров,
	и один товар может находиться в нескольких категориях.
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	id_category - категория
	id_product  - товар
	face        - наименование товара, переопределяющее наименования для конкретной категории
=cut
my %Attribute = (
	face        => undef,
	id_category => undef,
	id_product  => {mode => 'read'},
);

=begin nd
Method: Attribute ()
	Доступ к хешу с описанием членов класса.
	Может вызываться и как метод экземпляра, и как метод класса.

Returns:
	ссылку на описание членов класса
=cut
sub Attribute { \%Attribute }

=begin nd
Method: Table ( )
	Таблица хранения сущности в базе данных.

Returns:
	Строку 'prodlink'.
=cut
sub Table { 'prodlink' }

1;
