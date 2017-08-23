package ALKO::Catalog;
use base qw/ WooF::Object /;

=begin nd
Class: ALKO::Catalog
	Общие операции с каталогом. Нет таблицы. Работает с различными табличными сущностями.

	Категории организованы в дерево и хранятся в базе в виде направленного графа
	сверху (top) вниз (down). Нода может иметь только одного родителя.

	Специальная категория с id=0 представляет невидимый корень каталога.

	Товар может одновременно находиться в нескольких категориях.

	Дерево обхода susanin содержит циклические ссылки, поэтому данный класс нуждается в очищающем
	такие ссылки деструкторе <DESTROY>.

	Каталог состоит из следующих сущностей:
	ALKO::Catalog                        - сам Каталог реализует операции верхнего уровня
	ALKO::Catalog::Node                  - Нода дерева обхода содержит ссылки для обхода дерева и все необходимые для вывода данные в виде экземпляров
	ALKO::Catalog::Node::Show            - Нода дерева представления не содержит циклических ссылок и имеет только атрибуты, выводимые пользователю
	ALKO::Catalog::Category              - Категория является основным элементом каталога, группирующим товары и группы свойств, им присущие
	ALKO::Catalog::Category::Graph       - Дерево Категорий представлено направленным графом
	ALKO::Catalog::Product               - Товар
	ALKO::Catalog::Product::Link         - один Товар может одновременно находиться в разных категориях
	ALKO::Catalog::Property::Group       - Группа Свойств объединяет свойства, которые могут быть установлены товару; Группа привязывается к Категориям
	ALKO::Catalog::Property::Group::Link - Группа Свойств может одновременно быть привязана к разным Категориям
=cut

use strict;
use warnings;

use ALKO::Catalog::Node;
use ALKO::Catalog::Node::Show;
use ALKO::Catalog::Category;
use ALKO::Catalog::Category::Graph;
use ALKO::Catalog::Product;
use ALKO::Catalog::Product::Link;
use ALKO::Catalog::Property::Group;
use ALKO::Catalog::Property::Group::Link;

=begin nd
Variable: our $ROOT
	Номер категории, представляющей невидимый корень каталога.
=cut
our $ROOT = 0;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	curnode - текущая нода дерева обхода (susanin); чтобы вывести полный каталог, должна указывать на корень susanin'а;
	          вызывающему коду необходимо саму следить за инициализацией данного указателя перед проходом дерева Каталога
	show    - дерево без рекурсии для вывода пользователю
	susanin - дерево обхода
=cut
my %Attribute = (
	curnode => {mode => 'read'},
	show    => undef,
	susanin => undef,
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
Constructor: new ( )
	Конструктор сразу формирует полное дереро категорий.

	При формировании дерева категорий проход осуществляется по ребрам графа.
	Параллельно формируются два дерева - дерево прохода, и дерево представления.
	Дерево представления не имеет циклических ссылок, и поэтому в последующем может
	корректно выводиться в json.

	Каждая нода дерева прохода имеет ссылки на соответствующую ноду дерева представления,
	и ссылку на экземляр категории.

	Ребра помещаются в два хеша, соответствующие деревьям прохода (susanin) и представления (show)
	по ключу вершины down (потомка). По окончании формирования хешей все элементы оказываются связанными
	напревленным графом от корня через потомков, и поэтому могут быть представлены единственной нодой корня.

Returns:
	$self, содержащий дерево категорий без товара.
=cut
sub new {
	my ($class) = shift;
	my $self = $class->SUPER::new(@_);

	# Экземпляры категорий, для помещения в результирующее дерево в каждой ноде прохода
	my $category = ALKO::Catalog::Category->All->Hash;

	my (%show, %susanin);  # хеш дерева представления и хеш дерева прохода
	for (ALKO::Catalog::Category::Graph->All(SORT => ['sortn'])->List) {
		my ($id, $pid, $sortn) = @{$_}{qw/ down top sortn /};

		# Нода либо берется из хеша, если она там уже есть, либо создается новая
		my ($parent, $suparent);
		if (exists $show{$pid}) {
			$parent   = $show{$pid};
			$suparent = $susanin{$pid};
		} else {
			$show{$pid}    = $parent   = ALKO::Catalog::Node::Show->new;
			$susanin{$pid} = $suparent = ALKO::Catalog::Node->new;
		}

		my ($node, $sunode);
		if (exists $show{$id}) {
			$node   = $show{$id};
			$sunode = $susanin{$id};
		} else {
			$show{$id}    = $node   = ALKO::Catalog::Node::Show->new;
			$susanin{$id} = $sunode = ALKO::Catalog::Node->new;
		}

		# заполнение ноды представления
		$node->$_($category->{$id}{$_}) for qw/ id description visible /;
		$node->name($_->{face} // $category->{$id}{name});

		# заполнение ноды прохода
		$sunode->parent($id == $ROOT ? undef : $suparent);
		$sunode->sortn($sortn);
		$sunode->show($node);
		$sunode->category($category->{$id});

		# помещаем текущие ноды в родителей; у корня родителя нет
		unless ($id == $ROOT) {
			$parent->push_child($node);
			$suparent->push_child($sunode);
		}
	}

	# удаляем все некорневые ноды, т.к. они теперь связаны с корнем деревом (через child) и больше не нужны
	$_ == $ROOT or delete $show{$_}    for keys %show;
	$_ == $ROOT or delete $susanin{$_} for keys %susanin;

	# устанавливаем деревья и текущую ноду обхода
	$self->{show}    = $show{$ROOT};
	$self->{curnode} = $self->{susanin} = $susanin{$ROOT};

	$self;
}

=begin nd
Method: DESTROY ( )
	Деструктор очищает циклические ссылки в дереве обхода $self->{susanin}.

	Для каждой последней ноды в дереве категорий очищаются все ссылки с потомков на родителя
	и с родителя на массив потомков. Таким образом цикличность надежно разрывается.
	А поскольку проход дерева идет сверху вниз до конца и при подъеме слева направо, очищенные ноды
	не мешают завершить проход.
=cut
sub DESTROY {
	my $self = shift;

	# проходим все дерево с самого начала
	$self->{curnode} = $self->{susanin};

	my $clear = sub {
		my $cur     = shift;
		my $parent  = $cur->parent;
		my $sibling = $parent->child;

		while (my $bro = shift @$sibling) {
			$bro->parent(undef);  # сам $bro будет утилизирван в конце данного цикла
		}

		$parent->child(undef);  # у родителя удаляем ссылку на массив потомков, их больше нет
	};

	$self->_tree_walk(on_last_sibling => $clear);

	$self->SUPER::DESTROY;
}

=begin nd
Method: get_node ($category)
	Получить из каталога ноду, соответствующую указанной категории.

	Сначла достаются родительские категории, и начиная с корня осуществляется проход вниз
	по ведущему дереву. На каждом шаге вниз среди потомков ищется нода, которой соответствует текущий родитель.

Parameters:
	$category - категория, которой ищется соответствие; экземпляр <ALKO::Catalog::Category>

Returns:
	ноду <ALKO::Catalog::Node> - если нашлась
	undef                      - в противном случае
=cut
sub get_node {
	my ($self, $category) = @_;

	my $found = $self->{susanin};

	my $skip = 1;  # корень надо пропустить, так как мы и так уже в нем
	for ($category->parents->List) {
		--$skip, next if $skip;

		$found = $found->get_child($_) or return;
	}

	$category->id == $found->category->id ? $found : undef;
}

=begin nd
Method: link_products ( )
	Привязать к уже существующему дереву категорий товары.

	Пока товар привязыватеся напрямую в дерево презентации,
	но в будущем возможна более сложная логика, и тогда придется отдельно хранить
	исходные экземляры в дереве обхода, и презентационную версию в дереве просмотра.

Returns:
	$self
=cut
sub link_products {
	my $self = shift;

	$self->{curnode} = $self->{susanin};

	my $product = ALKO::Catalog::Product->All->Hash;
	my $link    = ALKO::Catalog::Product::Link->All->Hash('id_category');

	my $add_product = sub {
		my $node = shift;
		my $category = $node->category;

		if (exists $link->{$category->id}) {
			$node->show->push_product($product->{$_->id_product}) for @{$link->{$category->id}};
		}
	};

	$self->_tree_walk($add_product);

	$self;
}

=begin nd
Method: link_propgroups ( )
	Привязать к уже существующему дереву категорий группы свойств.

	Для каждой категории наследуются группы из родительских категорий.

Returns:
	$self
=cut
sub link_propgroups {
	my $self = shift;

	$self->{curnode} = $self->{susanin};

	my $group = ALKO::Catalog::Property::Group->All->Hash;
	my $link  = ALKO::Catalog::Property::Group::Link->All->Hash('id_category');

	my $add_group = sub {
		my $node = shift;
		my $category = $node->category;
		my $showgroup = $node->show->group;

		# сначала копируем у родителя все его группы
		if (defined $node->parent) {  # корню нечего наследовать
			@$showgroup = @{$node->parent->show->group};
		}

		# потом добавляем свои собственные
		if (exists $link->{$category->id}) {
			push @$showgroup, $group->{$_->id_propgroup} for @{$link->{$category->id}};
		}
	};

	$self->_tree_walk($add_group);

	$self;
}

=begin nd
Method: print ( )
	Получить дерево для отдачи клиенту.

	В возвращаемом дереве не будет циклических ссылок, поэтому оно будет однозначно выглядеть
	в любом формате представления. В случае циклических ссылок реальный данные и ссылки-заглушки
	для циклических нод могут располагаться где угодно в любом сочетании, и нет простого способа
	указывать конкретные места вывода данных и подстановок.

Returns:
	Дерево презентации.
=cut
sub print { +shift->{show} }

# =begin nd
# Method: _nextnode ( )
# 	Перейти в следующую ноду дерева обхода ($self->{susanin}.
#
# 	Текущая нода запоминается в атрибуте 'curnode'.
#
# 	Если есть обработчик 'on_last_sibling, он выполяется, если узел является последним потомком.
#
# Returns:
# 	следующая нода - если есть
# 	undef          - если дерево пройдено
# =cut
sub _nextnode {
	my ($self, $callback) = @_;
	my $cur = $self->{curnode};

	# если есть потомки, возвращаем первого из них
	return  $self->{curnode} = $cur->first_child if $cur->has_child;

	while (defined $cur->parent) {
		my $parent  = $cur->parent;
		my $sibling = $parent->child;
		my $i       = $cur->sortn;

		# если после текущей ноды есть еще братские ноды, переходим к следующей
		return $self->{curnode} = $sibling->[$i] if $i < $cur->n_siblings;

		# нода является последним потомком, выполяем обработчик для нее
		$callback->{on_last_sibling}->($cur) if exists $callback->{on_last_sibling};

		$cur = $parent;  # поднимаемся наверх, пока не дойдем до корня
	}

	undef;  # дерево обхода пройдено
}

=begin nd
Method: _tree_walk (@callback);
	Обойти дерево категорий.

	Необходимо, чтобы дерево уже существовало, но оно создается в конструкторе.

	Обход дерева нужен для его изменения/дополнения данными. Для этого в метод передаются
	обработчики-колбеки, выполняющие работу на указанных этапах прохода:
	on_node - для каждой ноды
	on_last_sibling - для ноды, являющейся последним потомком в списке потомков родителя.

Parameters:
	@callback - хеш колбеков, упакованный в массив где ключами должны быть предопредленные стадии
	выполенения: 'on_node', 'on_last_sibling'. Каждый тип колбека может быть указан только один раз.
=cut
sub _tree_walk {
	my $self = shift;
	my @callback = @_;

	my %callback;
	if (@callback == 1) {
		$callback{on_node} = shift;
	} else {
		%callback = @callback;
	}

	do {
		$callback{on_node}->($self->{curnode}) if exists $callback{on_node};
	} while $self->_nextnode(\%callback);
}

1;