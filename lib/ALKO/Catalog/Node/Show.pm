package ALKO::Catalog::Node::Show;
use base qw/ WooF::Object /;

=begin nd
Class: ALKO::Catalog::Node::Show
	Нода в дереве категорий show класса каталога <ALKO::Catalog>.
	
	Категории организованы в два синхронных дерева, и дерево show предназначено для вывода клиенту,
	так как не содержит рекурсивных ссылок, благодаря чему корректно визуализируется.
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	child       - массив потомков
	description - описание категории     <ALKO::Catalog::Category>
	group       - массив групп свойств данной категории, включая унаследованные
	id          - id категории           <ALKO::Catalog::Category>
	name        - наименование категории <ALKO::Catalog::Category>
	product     - массив товаров данной категории
	visible     - видимость категории    <ALKO::Catalog::Category>
=cut
my %Attribute = (
	child       => {default => []},
	description => {mode => 'write'},
	group       => {mode => 'read', default => []},
	id          => {mode => 'write'},
	name        => {mode => 'write'},
	product     => {default => []},
	visible     => {mode => 'write'},
);

=begin nd
Method: Attribute ( )
	Доступ к хешу с описанием членов класса.
	Может вызываться и как метод экземпляра, и как метод класса.

Returns:
	ссылку на описание членов класса
=cut
sub Attribute { \%Attribute }

=begin nd
Method: push_child ($child)
	Добавить потомка.
	
	Потомок добавляется в конец списка потомков, поэтому ответственность за соблюдением
	правильности сортировки лежит на вызывающем коде.
	
	Сама нода не имеет атрибута сортировки, так как является ведомой по отношению к ноде
	дерева обхода. Индекс сортировки может быть получен из него.
	
Parameters:
	$child - вставляемая нода
	
Returns:
	$self

=cut
sub push_child {
	my ($self, $child) = @_;
	
	push @{$self->{child}}, $child;
	
	$self;
}

=begin nd
Method: push_product ($product)
	Добавть товара в конец списка (атрибут 'product') товаров ноды.
	
	Товар не является экземпляром, как в случае с ведущим деревом обхода, а предсталяет
	из себя хеш с подготовленными полями. В будущем, вероятно, такое поведение изменится,
	и для презентации товара понадобится отдельный класс.
	
	Сортировка товаров внутри категории относится к прерогативе вызывающего кода.
	
Parameters:
	$product - добавляемый товар; экземпляр <ALKO::Catalog::Product>
	
Returns:
	$self
=cut
sub push_product {
	my ($self, $product) = @_;
	
	push @{$self->{product}}, $product;
	
	$self;
}

1;
