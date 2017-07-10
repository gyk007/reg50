package ALKO::Catalog::Category;
use base qw/ WooF::Object::Simple /;

=begin nd
Class: ALKO::Catalog::Category
	Категория товара.
	
	Категории организованы в дерево в классе <ALKO::Catalg>.
	
	Специальная категория с id=0 представляет невидимый корень каталога.
=cut

use strict;
use warnings;

use WooF::Debug;

use WooF::Error;
use WooF::Object::Collection;
use WooF::Object::Constants;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	description - полное описание
	name        - наименование
	parents     - коллекция родительских категорий от корня до текущей, включая текушую
	products    - товары, принадлежащие данной категории
	propgroups  - группы свойств привязанные непосредственно к данной категрии; наследованные не включены
	visible     - показывается ли при выводе данная категория со всеми своими потомками
	              если любой из родителей категории скрыт, то переопределить видимость данным флагом невозможно
=cut
my %Attribute = (
	description => undef,
	name        => undef,
	parents     => {type => 'cache'},
	products    => {
		type   => 'cache',
		extern => 'ALKO::Catalog::Product',
		maps   => {
			class  => 'ALKO::Catalog::Product::Link',
			master => 'id_category',
			slave  => 'id_product',
			set    => {face => 'face_effective'},
		},
	},
	propgroups  => {
		type   => 'cache',
		extern => 'ALKO::Catalog::Property::Group',
		maps   => {
			class  => 'ALKO::Catalog::Property::Group::Link',
			master => 'id_category',
			slave  => 'id_propgroup',
			set    => {
				face    => 'face_effective',
				joint   => 'joint',
				visible => 'visible',
				weight  => 'weight',
			},
		},
	},
	visible     => undef,
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
Method: complete_products ( )
	!Не готов. Получить полный список товаров в категории.
	
	Все товары, со всем свойствами и их значениями.
=cut
sub complete_products {
	my $self = shift;
	
	my $product   = $self->Has('products')   or return warn "Category::complete_products() requires extended products";
	my $propgroup = $self->Has('propgroups') or return warn "Category::complete_products() requires extended propgroups";
	my $parents = $self->parents;
	
	for ($parents->List) {
		$_->Expand('propgroups');
		debug 'PARENTS_FOR_AT_LOOP_END=', $_;
	}
	
# 	debug 'SELF_CATEGORY=', $self;
	
	$self;
}

=begin nd
Method: parents ( )
	Достать массив всех родительских категорий от корня до текущей.
	
	Экземпляры коллекции категорий-родителей расположены в порядке "сверху вниз" - от
	корня до текущей включительно. Коллекция будет привязана к атрибуту parents (хранится в $self->{extend}{parents}).
	
Returns:
	Коллекцию категорий от корня до текущей включительно.
=cut
sub parents {
	my $self = shift;
	my $class = ref $self;
	
	return $self->{extend}{parents} if exists $self->{extend} and exists $self->{extend}{parents};
	
	my $parents = $self->{extend}{parents} = WooF::Object::Collection->new($class)->Set_State(DWHLINK);
	
	# порядок выборки будет от текущей категории вверх до корня
	my $q = q{
		WITH RECURSIVE parents(top, down) as (
				SELECT top, down
				FROM category_graph
				WHERE down = ?
			UNION ALL
				SELECT g.top, g.down
				FROM parents p left join category_graph g on p.top = g.down
				WHERE p.down != ?
		)
		SELECT top, down FROM parents;
	};
	my $rows = $self->S->D->fetch_all($q, id_category => $self->{id}, id_category => $ALKO::Catalog::ROOT);

	$parents->Push($class->Get($_)) for map $_->{down}, reverse @$rows;

	$parents;
}

=begin nd
Method: Table ( )
	Таблица хранения сущности в базе данных.

Returns:
	Строку 'category'.
=cut
sub Table { 'category' }

1;
