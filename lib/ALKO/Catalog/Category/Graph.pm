package ALKO::Catalog::Category::Graph;
use base qw/ WooF::Object /;

=begin nd
Class: ALKO::Catalog::Category::Graph
	Дерево категорий каталога.
	
	Категории организованы в дерево и хранятся в базе в виде направленного графа
	сверху (top) вниз (down).
	Нода может иметь только одного родителя.
	
	Специальная категория с id=0 представляет невидимый корень каталога и не присутствует в описании дерева.
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	down  - потомок
	face  - имя категории, выводимое в дереве; переопределяет имя, хранимое в самой категории
	sortn - порядковый номер внутри родительской категории; отсчет с единицы, не с нуля
	top   - родитель
=cut
my %Attribute = (
	down  => {mode => 'read'},
	face  => undef,
	sortn => undef,
	top   => {mode => 'read'},
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
	Строку 'category_graph'.
=cut
sub Table { 'category_graph' }

1;
