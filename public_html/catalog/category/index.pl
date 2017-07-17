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
		
		my $category = ALKO::Catalog::Category->new($I->{category}) or return $Server->fail('Can\'t create a new category');
		$category->Save or return $Server->fail('Can\'t save category');

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

# Удалить указанную категорию
# URL: /catalog/category/?action=delete&id=25
#
# Удаление происходит мягко. Если категория не пуста, то удаления не выполняется.
# Удаление выполняется только в базе, дерево каталога не меняется
$Server->add_handler(DELETE => {
	input => {
		allow => [qw/ action id /],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);
		
		# если категория содержит товары, не удаляем категорию
		my $category = ALKO::Catalog::Category->Get(id => $I->{id}, EXPAND => 'products') or return $Server->fail("Can't delete Category: no such id=$I->{id}");
		return $Server->fail("Can't delete Category($I->{id}): containts products") if $category->has_products;
		
		# если категория содержит другие категории, не удаляем
		my $catalog = ALKO::Catalog->new;
		my $node = $catalog->get_node($category);
		return $Server->fail("Can't delete Category($I->{id}): containts childs") if $node->has_child;
		
		# удаляем привязку категории
		ALKO::Catalog::Category::Graph->Get(down => $category->id)->Remove;
		
		# сдвигаем младших сиблингов, чтобы закрыть дырку после удаления из дерева категории
		my $junior = ALKO::Catalog::Category::Graph->All(top => $node->parent->category->id, sortn => {'>', $node->sortn});
		$_->sortn($_->sortn - 1) for $junior->List;
		
		# удаляем саму категорию
		$category->Remove;
		
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
			category => [qw/ id name description visible /],
		],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);
		
		my $id = $I->{category}{id};
		my $category = ALKO::Catalog::Category->Get($id) or return $S->fail("No such Category($id)");
		
		$category->Edit($I->{category});
		
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

$Server->dispatcher(sub {
	my $S = shift;
	my $I = $S->I;
	
	return ['ADD']    if exists $I->{action} and $I->{action} eq 'add';
	return ['DELETE'] if exists $I->{action} and $I->{action} eq 'delete';
	return ['EDIT']   if exists $I->{action} and $I->{action} eq 'edit';
	return ['ITEM']   if exists $I->{id};
	
	['LIST'];
});

$Server->listen;
