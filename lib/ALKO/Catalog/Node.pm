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
	category - экземпляр категории <ALKO::Catalog::Category>, однозначно соответствующей данной ноде
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
Method: get_child ($category)
	Получить потомка, которому соответствует указанная категория.
	
Parameters:
	$category - категория для поиска
	
Returns:
	искомый потомок - если найден
	undef           - если не найден
=cut
sub get_child {
	my ($self, $category) = @_;
	
	$_->category->id == $category->id and return $_ for @{$self->{child}};
	
	undef;
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
Method: junior_sibling ( )
	Получить первого младшего брата в дереве.
	
	See: <older_sibling>
	
Returns:
	экземпляр данного класса - если сиблинг есть
	undef                    - в противном случае
=cut
sub junior_sibling {
	my $self = shift;
	
	# у корня нет сиблингов
	return unless $self->category->id;
	
	my $parent = $self->parent;

	return unless $self->{sortn} < @{$parent->{child}};
	
	$parent->{child}[$self->{sortn}];
}

=begin nd
Method: n_siblings ( )
	Получить количество братских нод.
	
Returns:
	Число - количество братьев, включая себя
=cut
sub n_siblings { scalar @{shift->{parent}{child}} }

=begin nd
Method: older_sibling ( )
	Получить первого старшего брата в дереве.
	
	See: <junior_sibling>
	
Returns:
	экземпляр данного класса - если сиблинг есть
	undef                    - в противном случае
=cut
sub older_sibling {
	my $self = shift;
	
	# у корня нет сиблингов
	return unless $self->category->id;
	
	# мы самые старшие
	return unless $self->{sortn} > 1;
	
	# sortn начинается с единицы, поэтому текущий индекс sortn-1, предыдущий sortn-2
	$self->parent->{child}[$self->{sortn} - 2];
}

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
