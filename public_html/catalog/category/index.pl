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
		my $id = $I->{id} or $S->fail("NOID: Action requires Category's ID");
		
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
		my $junior = ALKO::Catalog::Category::Graph->All(top => $node->parent->category->id, sortn => {'>', $node->sortn});
		$_->sortn($_->sortn - 1) for $junior->List;
		
		# удаляем саму категорию
		$category->Remove;
		
		delete @{$O}{qw/ category catalog node /};
		
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

# Определенная категория
# URL: /catalog/category/?id=125
$Server->add_handler(ITEM => {
	input => {
		allow => ['id'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		$O->{category} = ALKO::Catalog::Category->Get($I->{id});

		OK;
	},
});

# Подвинуть категорию влево, поменять местами с левым сиблингом.
# Если левого сиблинга нет, поднять на уровень родителя и поставить слева от него.
# Если левого сиблинга нет у категории - непосредственного потомка корня, завераем ошибкой.
# URL: /catalog/category/?action=left&id=125
$Server->add_handler(LEFT => {
	input => {
		allow => [qw/ action id /],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);
		my ($category, $catalog, $node) = @{$O}{qw/ category catalog node /};
		
		if (my $dst_node = $node->older_sibling) {
			my $src = ALKO::Catalog::Category::Graph->Get(down => $node->category->id);
			my $dst = ALKO::Catalog::Category::Graph->Get(down => $dst_node->category->id);
			
			$src->sortn($src->sortn - 1);
			$dst->sortn($dst->sortn + 1);
			
		} else {  # поднимаемся левее родителя
			my $parent = $node->parent;
			
			# на уровень корня подняться нельзя
			unless ($parent->category->id) {
				delete @{$O}{qw/ category catalog node /};
				return $S->fail("LOGIC: Can't Category move up to the Root-level");
			}
			
			# перемещаемая нода
			my $src = ALKO::Catalog::Category::Graph->Get(down => $category->id);
			
			# добавляем копию в новое место
			my $dst = ALKO::Catalog::Category::Graph->new($src);
			
			# down уникален в базе
			$src->Remove;
			
			my $new_top = $parent->parent->category->id;
			$dst->top($parent->parent->category->id);
			$dst->sortn($parent->sortn);
			
			# на новом месте сдвигаем вправо всех сиблингов, начиная с родителя
			my $junior = ALKO::Catalog::Category::Graph->All(top => $parent->parent->category->id, sortn => {'>=', $parent->sortn});
			$_->sortn($_->sortn + 1) for $junior->List;
			
			# сдвигаем оставшихся сиблингов справа, чтобы закрыть дырку
			$junior = ALKO::Catalog::Category::Graph->All(top => $parent->category->id, sortn => {'>', $node->sortn});
			$_->sortn($_->sortn - 1) for $junior->List;
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
		
		my $new_parent = $node->junior_sibling or $S->fail("NOSUCH: Destination parent for moving right-down not exists");

		my $src = ALKO::Catalog::Category::Graph->Get(down => $category->id);
		my $dst = ALKO::Catalog::Category::Graph->new($src);
		$src->Remove;  # необходимо удалить до вставки $dst, иначе ключи дублируются
		
		$dst->top($new_parent->category->id);
		$dst->sortn($new_parent->has_child + 1);
		
		# сдвигаем младших сиблингов, чтобы закрыть дырку после удаления из дерева категории
		my $junior = ALKO::Catalog::Category::Graph->All(top => $node->parent->category->id, sortn => {'>', $node->sortn});
		$_->sortn($_->sortn - 1) for $junior->List;

		delete @{$O}{qw/ category catalog node /};

		OK;
	},
});

$Server->dispatcher(sub {
	my $S = shift;
	my $I = $S->I;
	
	return ['ADD']                        if exists $I->{action} and $I->{action} eq 'add';
	return ['EDIT']                       if exists $I->{action} and $I->{action} eq 'edit';
	return [qw/ CHECK_EMPTY LEFT /]       if exists $I->{action} and $I->{action} eq 'left';
	return [qw/ CHECK_EMPTY RIGHT_DOWN /] if exists $I->{action} and $I->{action} eq 'rdown';
	return [qw/ CHECK_EMPTY DELETE /]     if exists $I->{action} and $I->{action} eq 'delete';
	return ['ITEM']                       if exists $I->{id};
	
	['LIST'];
});

$Server->listen;
