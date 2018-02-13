#! /usr/bin/perl
#
# Homepage
#

use strict;
use warnings;

use WooF::Debug;
use DateTime;
use ALKO::Mob::Server;
use ALKO::Mob::Tag;
use ALKO::Mob::Tag::News;
use ALKO::Mob::Tag::Manager;

my $Server = WooF::Server->new(output_t => 'JSON', auth => 0);

# Простейший обработчик. Клиенту отдается статичный шаблон, в лог веб-сервера - версия постгрис.
# URL: /
$Server->add_handler(DEFAULT => {
	call => sub {
		my $S = shift;

		my $rc = $S->D->fetch('SELECT VERSION()');
		debug 'VERSION=', $rc;

		OK;
	},
});

# Получить данные представителя магазина
#
# GET
# URL: /?
#   action = list
#
$Server->add_handler(LIST => {
	input => {
		allow => ['action'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		$O->{tag_list} = ALKO::Mob::Tag->All->List;

		OK;
	},
});

# Добавить Тег
#
# GET
# URL: /?
#   action          = add
#   tag.id          = 1
#   tag.name        = String
#   tag.description = String
#
$Server->add_handler(ADD => {
	input => {
		allow => [
			'action',
			tag => [qw/ id name description /],
		],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $tag;
		if ($I->{tag}{id}) {
			$tag = ALKO::Mob::Tag->Get($I->{tag}{id}) or return $S->fail("NOSUCH: Can\'t get Tag: no such tag(id => $I->{tag}{id})");
			$tag->name($I->{tag}{name});
			$tag->description($I->{tag}{description});
		} else {
			$tag = ALKO::Mob::Tag->new({
				name        => $I->{tag}{name},
				description => $I->{tag}{description},
			})->Save;
		}

		OK;
	},
});


# Удалить тег
#
# GET
# URL: /?
#   action = delete
#   tag.id = 1
#
$Server->add_handler(DELETE => {
	input => {
		allow => [
			'action',
			tag => [qw/ id /],
		],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $tag = ALKO::Mob::Tag->Get($I->{tag}{id}) or return $S->fail("NOSUCH: Can\'t get Tag: no such tag(id => $I->{tag}{id})");

		my $news_tag    = ALKO::Mob::Tag::News->All(id_mob_news_tag => $tag->id)->List;
		my $manager_tag = ALKO::Mob::Tag::Manager->All(id_mob_news_tag => $tag->id)->List;

		$_->Remove for @$news_tag;
		$_->Remove for @$manager_tag;

		$tag->Remove;

		OK;
	},
});

$Server->dispatcher(sub {
	my $S = shift;
	my $I = $S->I;
	debug $I;
	return ['LIST']    if exists $I->{action} and $I->{action} eq 'list';
	return ['ADD']     if exists $I->{action} and $I->{action} eq 'add';
	return ['DELETE']  if exists $I->{action} and $I->{action} eq 'delete';

	['DEFAULT'];
});


$Server->listen;
