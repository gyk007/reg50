#! /usr/bin/perl
#
# Homepage
#

use strict;
use warnings;

use WooF::Debug;
use DateTime;
use ALKO::Mob::Server;

use ALKO::Mob::Manager;
use ALKO::Mob::News::Favorite;
use ALKO::Session;
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

		my $manager = ALKO::Mob::Manager->All;

		my $tags = ALKO::Mob::Tag::Manager->All(id_mob_manager => [keys %{$manager->Hash('id')}])->Hash('id_mob_manager');

		for my $item (@{$manager->List}) {
			$item->{tags} = [];
			if ($tags->{$item->{id}}) {
				push @{$item->{tags}}, $_->id_mob_news_tag for @{ $tags->{$item->{id}} };
			}
		}

		$O->{manager_list} = $manager->List;

		OK;
	},
});

# Сбросить пароль
#
# GET
# URL: /?
#   action = add
#   manger.password = String
#	manger.email    = String
#   manger.phone    = String
#
$Server->add_handler(ADD => {
	input => {
		allow => [
			'action',
			manager => [qw/ password email phone name id tags/],
		],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $manager;
		if ($I->{manager}{id}) {
			$manager = ALKO::Mob::Manager->Get($I->{manager}{id}) or return $S->fail("NOSUCH: Can\'t get Manager: no such manager(id => $I->{manager}{id})");
			$manager->password($I->{manager}{password});
			$manager->email($I->{manager}{email});
			$manager->phone($I->{manager}{phone});
			$manager->name($I->{manager}{name});
		} else {
			$manager = ALKO::Mob::Manager->new({
				password => $I->{manager}{password},
				email    => $I->{manager}{email},
				phone    => $I->{manager}{phone},
				name     => $I->{manager}{name},
			})->Save;
		}

		my $old_tags = ALKO::Mob::Tag::Manager->All(id_mob_manager => $manager->id)->List;
		$_->Remove for @$old_tags;

		if ($I->{manager}{tags}) {
			my @tags  = split(',', $I->{manager}{tags});
			for (@tags) {
				ALKO::Mob::Tag::Manager->new({
					id_mob_manager      =>  $manager->id,
					id_mob_news_tag  =>  $_,
				})->Save;
			}
		}

		OK;
	},
});


# Удалит менеджера
#
# GET
# URL: /?
#   action = delete
#   manager.id       = 1
#
$Server->add_handler(DELETE => {
	input => {
		allow => [
			'action',
			manager => [qw/ id /],
		],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $manager = ALKO::Mob::Manager->Get($I->{manager}{id}) or return $S->fail("NOSUCH: Can\'t get Manager: no such manager(id => $I->{manager}{id})");

		my $favorite = ALKO::Mob::News::Favorite->All(id_mob_manager => $manager->id)->List;
		my $session  = ALKO::Session->All(id_mob_manager => $manager->id)->List;
		my $tags     = ALKO::Mob::Tag::Manager->All(id_mob_manager => $manager->id)->List;

		$_->Remove for @$tags;
		$_->Remove for @$favorite;
		$_->Remove for @$session;

		$manager->Remove;

		OK;
	},
});

$Server->dispatcher(sub {
	my $S = shift;
	my $I = $S->I;
	debug  $I;
	return ['LIST']    if exists $I->{action} and $I->{action} eq 'list';
	return ['ADD']     if exists $I->{action} and $I->{action} eq 'add';
	return ['DELETE']  if exists $I->{action} and $I->{action} eq 'delete';

	['DEFAULT'];
});


$Server->listen;
