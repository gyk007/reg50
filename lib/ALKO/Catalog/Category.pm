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

use WooF::Error;
use WooF::Object::Collection;
use WooF::Object::Constants;

use ALKO::Catalog::Property;
use ALKO::Catalog::Property::Value;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	description      - полное описание
	groups_effective - группы свойств, включая наследованные
	name             - наименование
	parents          - коллекция родительских категорий от корня до текущей, включая текушую
	products         - товары, принадлежащие данной категории
	propgroups       - группы свойств привязанные непосредственно к данной категрии; наследованные не включены
	visible          - показывается ли при выводе данная категория со всеми своими потомками
	                   если любой из родителей категории скрыт, то переопределить видимость данным флагом невозможно
=cut
my %Attribute = (
	description      => undef,
	name             => undef,
	groups_effective => {mode => 'read/write', type => 'cache'},
	parents          => {type => 'cache'},
	products         => {
	                        mode   => 'read',
	                        type   => 'cache',
	                        extern => 'ALKO::Catalog::Product',
	                        maps   => {
	                                      class  => 'ALKO::Catalog::Product::Link',
	                                      master => 'id_category',
	                                      slave  => 'id_product',
	                                      set    => {face => 'face_effective'},
	                        },
	},
	propgroups      => {
	                        mode   => 'read',
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
	visible         => undef,
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
	Получить полный список товаров в категории.
	
	Все товары, со всеми свойствами и их значениями. Карточка товара.
	
Returns:
	$self
=cut
sub complete_products {
	my $self = shift;
	
	my $product   = $self->Has('products')   or return warn "Category::complete_products() requires extended products";
	my $propgroup = $self->Has('propgroups') or return warn "Category::complete_products() requires extended propgroups";
	my $parents   = $self->parents;
	
	# проходим от корневой категории до текущей, собирая все встретившиеся категории
	for ($parents->List) {
		# когда коллекция научится расширяться, можно будет заменить на получение групп до цикла
		$_->Expand('propgroups');
		
		# на первом проходе (корневая категория) собранных групп еще нет, создаем под них атрибут в else
		if ($self->groups_effective) {
			# каждую группу либо добавляем, если такой еще не было, либо переопределяем уже имющуюся
			for ($_->propgroups->List) {
				if (my $must_redefine = $self->groups_effective->First_Item(id => $_->{id})) {
					$must_redefine->joint($_->joint);
				} else {
					$self->groups_effective->Push($_);
				}
			}
		} else {
			# можно будет избавиться от явного создания коллекции, если научить сеттеры в Object создавать
			# коллекцию автоматически при Push в неопределенный cache
			$self->groups_effective(WooF::Object::Collection->new('ALKO::Catalog::Property::Group')->Set_State(DWHLINK));
			
			# в корневой категории наследовать нечего, просто добавлем группы из нее
			$self->groups_effective->Push($_->propgroups->List);
		}
	}
	
	# эталонные свойства для копирования в каждый продукт
	$self->groups_effective->Expand('properties');
	
	# развесистый хеш значений свойств с обособленными ключам, чтобы легче дампить
	my %value;
	$value{id_product}{$_->id_product}{id_propgroup}{$_->id_propgroup}{n_property}{$_->n_property} = $_->val_int
		for ALKO::Catalog::Property::Value->All(id_product => [$self->products->List('id')])->List;

	# копируем в каждый товар все свойства и заполняем значениями
	for my $product ($self->products->List) {
		# копируем группы
		$product->properties($self->groups_effective->Clone(id => 'id')->Set_State(NOSYNC));
		
		for my $dst_group ($product->properties->List) {
			# копируем свойства
			my $src_group = $self->groups_effective->First_Item(id => $dst_group->id);
			$dst_group->properties($src_group->properties->Clone(id_propgroup => 'id_propgroup', n => 'n')->Set_State(NOSYNC));

			# устанавливаем каждому свойству значение
			for ($dst_group->properties->List) {
				$_->value($value{id_product}{$product->id}{id_propgroup}{$_->id_propgroup}{n_property}{$_->n})
					if
							exists $value{id_product}{$product->id}
						and
							exists $value{id_product}{$product->id}{id_propgroup}{$_->id_propgroup}
						and
							exists $value{id_product}{$product->id}{id_propgroup}{$_->id_propgroup}{n_property}{$_->n};
			}
		}
	}
	
	$self;
}

=begin nd
Method: has_products ( )
	Содержит ли категория товары.
	
Returns:
	количество товаров в категории - если есть
	0                              - если нет
=cut
sub has_products {
	my $self = shift;
	
	$self->Expand('products') unless $self->products;
	
	scalar @{$self->products->List};
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
