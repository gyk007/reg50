#! /usr/bin/perl
#
# Homepage
#

use strict;
use warnings;

use WooF::Debug;
use DateTime;
use ALKO::Mob::Server;

use ALKO::Mob::News;
use ALKO::Mob::News::Favorite;
use ALKO::Mob::Tag::News;
use ALKO::Mob::Tag;

my $Server = ALKO::Mob::Server->new(output_t => 'JSON', auth => 1);

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
#	sort   = string
#
$Server->add_handler(LIST => {
	input => {
		allow => ['action', 'sort'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $sort = $I->{sort};

		my $dt_weak  = DateTime->now;
		my $dt_month = DateTime->now;
		my $dt_year  = DateTime->now;

		$dt_weak->subtract(days => 7);
		$dt_month->subtract(months => 1);
		$dt_year->subtract(years => 1);

		my $favorite = ALKO::Mob::News::Favorite->All(id_mob_manager => $O->{SESSION}{id_mob_manager})->Hash('id_mob_news');

		my $news;
		$news = ALKO::Mob::News->All(ctime => {'>=', $dt_weak->ymd})  if $sort eq 'week';
		$news = ALKO::Mob::News->All(ctime => {'>=', $dt_month->ymd}) if $sort eq 'month';
		$news = ALKO::Mob::News->All(ctime => {'>=', $dt_year->ymd})  if $sort eq 'year';
		$news = ALKO::Mob::News->All(id => [keys %$favorite])         if $sort eq 'favorite';

		my @id_news = keys %{$news->Hash('id')};
		my $tag_ref = ALKO::Mob::Tag::News->All(id_mob_news => @id_news);
		my @id_tags = keys %{$tag_ref->Hash('id_mob_news_tag')};


		ALKO::Mob::Tag::News



	 	for (@{$O->{news_list}}) {
	 		$_->{in_favorite} = 1 if defined $favorite->{$_->{id}};
	 	}

		OK;
	},
});

# Получить данные представителя магазина
#
# GET
# URL: /?
#   action  = list
#	id_news = 1
#
$Server->add_handler(ADD_DELETE_FAVORITTE => {
	input => {
		allow => ['action', 'id_news'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $favorite = ALKO::Mob::News::Favorite->Get(id_mob_news => $I->{id_news}, id_mob_manager => $O->{SESSION}{id_mob_manager});

		if ($favorite) {
			$favorite->Remove;
		} else {
			ALKO::Mob::News::Favorite->new({
				id_mob_news    => $I->{id_news},
				id_mob_manager => $O->{SESSION}{id_mob_manager},
			});
		}

		OK;
	},
});


$Server->dispatcher(sub {
	my $S = shift;
	my $I = $S->I;
	debug $I;
	return ['LIST']                 if exists $I->{action} and $I->{action} eq 'list';
	return ['ADD_DELETE_FAVORITTE'] if exists $I->{action} and $I->{action} eq 'add_delete_favorite';


	['DEFAULT'];
});


$Server->listen;
