#! /usr/bin/perl
#
# Категории. Дерево каталога.
#

use strict;
use warnings;

use WooF::Debug;
use WooF::Server;
use ALKO::Catalog;
use ALKO::Catalog::Category;
use ALKO::Catalog::Category::Graph;
use ALKO::Catalog::Product;
use ALKO::Catalog::Product::Link;

my $Server = WooF::Server->new(output_t => 'JSON');

# Добавить категорию в корень
# Вставка происходит последним потомком корня
#
# Скорее всего POST
# URL: /catalog/category/?
#   action=add
#   category.name=beer
#   category.description=light fun
#   category.visible=true
#   category.face=Beer
#
$Server->add_handler(ADD => {
	input => {
		allow => ['action', category => [qw/ name description visible face /]],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $category = ALKO::Catalog::Category->new($I->{category}) or return $S->fail('Can\'t create a new category');
		$category->Save or return $S->fail('Can\'t save category');

		my $catalog = ALKO::Catalog->new;
		my $parent = $catalog->curnode;

		ALKO::Catalog::Category::Graph->new(
			top   => $ALKO::Catalog::ROOT,
			down  => $category->id,
			face  => exists $O->{category}{face} ? $O->{category}{face} : undef, # face принадлежит привязке в дерево, а не категории
			sortn => $parent->has_child + 1,
		);

		$O->{category} = $category->id;

		OK;
	},
});

# Получить все продукты для добавления в категорию.
# Категория должна быть пуста.
# POST
# URL: /catalog/category/?
#   action=add_product
#   id_category = 1
#   id_product  = 2
#
$Server->add_handler(ADD_PRODUCT => {
	input => {
		allow => ['action', 'id_category', 'id_product'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $product  = ALKO::Catalog::Product->Get(id => $I->{id_product})   or return $S->fail("NOSUCH: Can\'t get Product: no such Product(id => $I->{id_product})");
		my $category = ALKO::Catalog::Category->Get(id => $I->{id_category}) or return $S->fail("NOSUCH: Can\'t get Product: no such Category(id => $I->{id_category})");

		ALKO::Catalog::Product::Link->new({
			id_product  => $product->id,
			id_category => $category->id,
		});

		OK;
	},
});

# Получить все продукты для добавления в категорию.
# URL: /catalog/category/?action = all_product
#
$Server->add_handler(ALL_PRODUCT => {
	input => {
		allow => [qw/ action /],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $links      = ALKO::Catalog::Product::Link->All;
		my $categories = ALKO::Catalog::Category->All->Hash;

		# Добавляем имя категории в ссылку
		$_->name_category($categories->{$_->{id_category}}->name) for $links->List;

		my $products = ALKO::Catalog::Product->All;
		$links = $links->Hash('id_product');

		# Добавляем ссылку в товар
		$_->link($links->{$_->{id}}) for $products->List;

		$O->{products} = $products->List;

		OK;
	},
});

# Вспомогательный хендлер по проверке чистоты категории.
# Категория не должна содержать другие категории или товары
# В oflow помещает категорию, каталог и ноду.
$Server->add_handler(CHECK_EMPTY => {
	input => {
		allow => [qw/ action id /],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		# указан id категории
		my $id = $I->{id} or return $S->fail("NOID: Action requires Category's ID");

		# категория существует
		my $category = ALKO::Catalog::Category->Get(id => $id, EXPAND => 'products') or return $S->fail("NOSUCH: Can't operate on Category: no such id=$id");

		# не содержит товаров
		return $S->fail("PRODEXIST: Can't operate on Category($id): containts products") if $category->has_products;

		# категория не содержит другие категории
		my $catalog = ALKO::Catalog->new;
		my $node = $catalog->get_node($category);
		return $S->fail("CATEGORYEXIST: Can't operate on Category($I->{id}): containts childs") if $node->has_child;

		@{$O}{qw/ category catalog node /} = ($category, $catalog, $node);

		OK;
	},
});

# Удалить указанную категорию
# URL: /catalog/category/?action=delete&id=25
#
# Удаление выполняется только в базе, дерево каталога не меняется
# Предварительно производится проверка в CHECK_EMPTY.
$Server->add_handler(DELETE => {
	input => {
		allow => [qw/ action id /],
	},
	call => sub {
		my $S = shift;
		my $O = $S->O;
		my ($category, $catalog, $node) = @{$O}{qw/ category catalog node /};
# 		my $node = $catalog->get_node($category);

		# удаляем привязку категории
		ALKO::Catalog::Category::Graph->Get(down => $category->id)->Remove;

		# сдвигаем младших сиблингов, чтобы закрыть дырку после удаления из дерева категории
		my $junior = ALKO::Catalog::Category::Graph->All(top => $node->parent->id, sortn => {'>', $node->sortn}, SORT => ['sortn']);
		$_->sortn($_->sortn - 1)->Save for $junior->List;

		# удаляем саму категорию
		$category->Remove;

		delete @{$O}{qw/ category catalog node /};

		OK;
	},
});

# Получить все продукты для добавления в категорию.
# Категория должна быть пуста.
# POST
# URL: /catalog/category/?
#   action=delete_product
#   id_category = 1
#   id_product  = 2
#
$Server->add_handler(DELETE_PRODUCT => {
	input => {
		allow => ['action', 'id_category', 'id_product'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $product  = ALKO::Catalog::Product->Get(id => $I->{id_product})   or return $S->fail("NOSUCH: Can\'t get Product: no such Product(id => $I->{id_product})");
		my $category = ALKO::Catalog::Category->Get(id => $I->{id_category}) or return $S->fail("NOSUCH: Can\'t get Product: no such Category(id => $I->{id_category})");

		my $link = ALKO::Catalog::Product::Link->Get(id_product => $product->id, id_category => $category->id) or return $S->fail("NOSUCH: Can\'t get Product: no such Link(id_product => $product->id, id_category => $category->id)");

		$link->Remove;

		OK;
	},
});

# Редактирование категории
# URL: /catalog/category/?
# POST:
# action=edit
# category.id=125
# category.name=new name
# category.description=new description
# category.visible=new true/false
$Server->add_handler(EDIT => {
	input => {
		allow => [
			'action',
			category => [qw/ id name face description visible /],
		],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $id = $I->{category}{id};
		my $category = ALKO::Catalog::Category->Get($id) or return $S->fail("No such Category($id)");

		$category->Edit($I->{category});

		# face является атрибутом ноды дерева, а не категории
		if (exists $I->{category}{face}) {
			my $node = ALKO::Catalog::Category::Graph->Get(down => $id) or return $S->fail("Can't edit face on unbound Category($id)");

			$node->face($I->{category}{face} eq '' ? undef : $I->{category}{face});
		}

		OK;
	},
});

# Определенная категория с товарами, свойствами, значениями.
# URL: /catalog/category/?id=125
$Server->add_handler(ITEM => {
	input => {
		allow => ['id'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);
		my $id = $I->{id};

		my $category = ALKO::Catalog::Category->Get(id => $id, EXPAND => [qw/ products propgroups /]) or return $S->fail("Can't get Category($id)");
		$category->complete_products;

		# Чистим структуру для вывода
		$category->{products} = $category->{extend}{products}{elements};
		delete $category->{groups_effective};
		delete $category->{extend};

		$O->{category} =  $category;
		OK;

	},
});

# Подвинуть категорию влево, поменять местами с левым сиблингом.
# Если левого сиблинга нет, поднять на уровень родителя и поставить слева от него.
# Если левого сиблинга нет у категории - непосредственного потомка корня, завершаем ошибкой.
# URL: /catalog/category/?action=left&id=125
$Server->add_handler(LEFT => {
	input => {
		allow => [qw/ action id /],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		# указан id категории
		my $id = $I->{id} or return $S->fail("NOID: Action requires Category's ID");

		# категория существует
		my $category = ALKO::Catalog::Category->Get(id => $id, EXPAND => 'products') or return $S->fail("NOSUCH: Can't operate on Category: no such id=$id");

		# категория не содержит другие категории
		my $catalog = ALKO::Catalog->new;
		my $node = $catalog->get_node($category);
		return $S->fail("CATEGORYEXIST: Can't operate on Category($I->{id}): containts childs") if $node->has_child;

		if (my $dst_node = $node->older_sibling) {
			my $src = ALKO::Catalog::Category::Graph->Get(down => $node->id);
			my $dst = ALKO::Catalog::Category::Graph->Get(down => $dst_node->id);

			# нельзя просто поменять местами, поэтому сначала перемещаем $src в конец
			$src->sortn($node->n_siblings + 1);
			$src->Save;
			$dst->sortn($dst->sortn + 1);
			$dst->Save;
			$src->sortn($dst->sortn - 1);

		} else {  # поднимаемся левее родителя
			my $parent = $node->parent;

			# на уровень корня подняться нельзя
			unless ($parent->id) {
				delete @{$O}{qw/ category catalog node /};
				return $S->fail("LOGIC: Can't Category move up to the Root-level");
			}

			# перемещаемая нода
			my $src = ALKO::Catalog::Category::Graph->Get(down => $category->id);

			# добавляем копию в новое место
			my $dst = ALKO::Catalog::Category::Graph->new($src);
			$dst->top($parent->parent->id);
			$dst->sortn($parent->sortn);

			# down уникален в базе, старый надо уничтожить до вставки
			$src->Remove;

			# на новом месте сдвигаем вправо всех сиблингов, начиная с родителя
			my $junior = ALKO::Catalog::Category::Graph->All(top => $parent->parent->id, sortn => {'>=', $parent->sortn}, SORT => ['sortn DESC']);
			$_->sortn($_->sortn + 1)->Save for $junior->List;

			# на месте $src сдвигаем налево всех оставшихся сиблингов справа, чтобы закрыть дырку
			$junior = ALKO::Catalog::Category::Graph->All(top => $parent->id, sortn => {'>', $node->sortn}, SORT => ['sortn']);
			$_->sortn($_->sortn - 1)->Save for $junior->List;
		}

		# json не может вывести корректно рекурсивную структуру
		delete @{$O}{qw/ category catalog node /};

		OK;
	},
});

# Список катагорий
# URL: /catalog/category/
$Server->add_handler(LIST => {
	input => {
		allow => [],
	},
	call => sub {
		my $S = shift;

		$S->O->{categories} = ALKO::Catalog::Category->All(SORT => 'DEFAULT')->List;

		OK;
	},
});

# Подвинуть категорию направо, поменять местами с правым сиблингом.
# Если правого сиблинга нет, поднять на уровень родителя и поставить справа от него.
# Если правого сиблинга нет у категории - непосредственного потомка корня, завершаем ошибкой.
# URL: /catalog/category/?action=right&id=125
$Server->add_handler(RIGHT => {
	input => {
		allow => [qw/ action id /],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		# указан id категории
		my $id = $I->{id} or return $S->fail("NOID: Action requires Category's ID");

		# категория существует
		my $category = ALKO::Catalog::Category->Get(id => $id, EXPAND => 'products') or return $S->fail("NOSUCH: Can't operate on Category: no such id=$id");

		# категория не содержит другие категории
		my $catalog = ALKO::Catalog->new;
		my $node = $catalog->get_node($category);
		return $S->fail("CATEGORYEXIST: Can't operate on Category($I->{id}): containts childs") if $node->has_child;

		if (my $dst_node = $node->junior_sibling) {
			my $src = ALKO::Catalog::Category::Graph->Get(down => $node->id);
			my $dst = ALKO::Catalog::Category::Graph->Get(down => $dst_node->id);

			# нельзя просто поменять местами, поэтому сначала перемещаем $src в конец
			$src->sortn($node->n_siblings + 1);
			$src->Save;
			$dst->sortn($dst->sortn - 1);
			$dst->Save;
			$src->sortn($dst->sortn + 1);

		} else {  # поднимаемся правее родителя
			my $parent = $node->parent;

			# на уровень корня подняться нельзя
			unless ($parent->id) {
				delete @{$O}{qw/ category catalog node /};
				return $S->fail("LOGIC: Can't Category move up to the Root-level");
			}

			# перемещаемая нода
			my $src = ALKO::Catalog::Category::Graph->Get(down => $category->id);

			# добавляем копию в новое место
			my $dst = ALKO::Catalog::Category::Graph->new($src);
			$dst->top($parent->parent->id);
			$dst->sortn($parent->sortn + 1);


			# на новом месте сдвигаем вправо всех сиблингов справа от родителя, чтобы освободить место под вставку
			my $junior = ALKO::Catalog::Category::Graph->All(top => $parent->parent->id, sortn => {'>', $parent->sortn}, SORT => ['sortn DESC']);
			$_->sortn($_->sortn + 1)->Save for $junior->List;

			# down уникален в базе, поэтому нужно утилизировать раньше вставки
			$src->Remove;
		}

		# json не может вывести корректно рекурсивную структуру
		delete @{$O}{qw/ category catalog node /};

		OK;
	},
});

# Переместить категорию в потомки правого сиблинга.
# Категория становится последним потомком.
# Категория должна быть пуста.
# URL: /catalog/category/?action=rdown&id=125
$Server->add_handler(RIGHT_DOWN => {
	input => {
		allow => [qw/ action id /],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);
		my ($category, $catalog, $node) = @{$O}{qw/ category catalog node /};

		my $dst_parent = $node->junior_sibling or return $S->fail("NOSUCH: Destination parent for moving right-down not exists");

		my $src = ALKO::Catalog::Category::Graph->Get(down => $category->id);
		my $dst = ALKO::Catalog::Category::Graph->new($src);
		$src->Remove;  # необходимо удалить до вставки $dst, иначе ключи дублируются

		$dst->top($dst_parent->id);
		$dst->sortn($dst_parent->has_child + 1);

		# сдвигаем младших сиблингов, чтобы закрыть дырку после удаления из дерева категории
		my $junior = ALKO::Catalog::Category::Graph->All(top => $node->parent->id, sortn => {'>', $node->sortn}, SORT => ['sortn']);
		$_->sortn($_->sortn - 1)->Save for $junior->List;

		delete @{$O}{qw/ category catalog node /};

		OK;
	},
});

$Server->dispatcher(sub {
	my $S = shift;
	my $I = $S->I;

	return ['ADD']                        if exists $I->{action} and $I->{action} eq 'add';
	return ['ADD_PRODUCT']                if exists $I->{action} and $I->{action} eq 'add_product';
	return ['EDIT']                       if exists $I->{action} and $I->{action} eq 'edit';
	return ['ALL_PRODUCT']                if exists $I->{action} and $I->{action} eq 'all_product';
	return [qw/ LEFT /]                   if exists $I->{action} and $I->{action} eq 'left';
	return [qw/ RIGHT /]                  if exists $I->{action} and $I->{action} eq 'right';
	return [qw/ CHECK_EMPTY RIGHT_DOWN /] if exists $I->{action} and $I->{action} eq 'rdown';
	return [qw/ CHECK_EMPTY DELETE /]     if exists $I->{action} and $I->{action} eq 'delete';
	return ['DELETE_PRODUCT']             if exists $I->{action} and $I->{action} eq 'delete_product';
	return ['ITEM']                       if exists $I->{id};

	['LIST'];
});

$Server->listen;
