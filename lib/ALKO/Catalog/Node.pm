package ALKO::Catalog::Node;
use base qw/ WooF::Object /;

=begin nd
Class: ALKO::Catalog::Node
	Нода в дереве прохода категорий (атрибут 'susanin') класса каталога <ALKO::Catalog>.
	
	Категории организованы в два синхронных дерева, и дерево susanin предназначено для
	обхода дерева используя циклические ссылки: родитель имеет ссылку на потомков, а каждый
	потомок содержит ссылку на родителя.
=cut

use strict;
use warnings;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	category - экземпляр категории <ALKO::Catalog::Category>, однозначно соответствующий данной ноде
	child    - массив потомков
	parent   - родительская нода
# 	product  - массив товаров, принадлежащих категории
	show     - нода в параллельном "дереве вывода", екземпляр <ALKO::Catalog::Node::Show>
	sortn    - позиция ноды (отсчет с единицы) в списке сиблингов
=cut
my %Attribute = (
	category => {mode => 'read/write'},
	child    => {mode => 'read/write', default => []},
	parent   => {mode => 'read/write'},
# 	product  => {default => []},
	show     => {mode => 'read/write'},
	sortn    => {mode => 'read/write'},
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
Method: first_child ( )
	Получить первого потомка.
	
	Номера потомков определяются полем сортировки 'sortn'.
	
Returns:
	экземпляр ноды - если если у текущей ноды есть потомки
	undef - если потомков нет
=cut
sub first_child {
	my $self = shift;
	
	@{$self->{child}} ? $self->{child}->[0] : undef;
}

=begin nd
Method: has_child ( )
	Имеет ли нода потомков?
	
Returns:
	Количество потомков.
	0 - если потомков нет.
=cut
sub has_child { scalar @{shift->{child}} }

=begin nd
Method: n_siblings ( )
	Получить количество братских нод.
	
Returns:
	Число - количество братьев.
=cut
sub n_siblings { scalar @{shift->{parent}{child}} }

=begin nd
Method: push_child ($child)
	Добавить потомка.
	
	Потомок добавляется в конец списка потомков, вне зависимости от атрибута sortn,
	поэтому ответственность за соблюдением правильности сортировки лежит на вызывающем коде.
	
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

1;
