#! /usr/bin/perl
#
# Homepage
#

use strict;
use warnings;
use utf8;
use WooF::Debug;
use DateTime;
use JSON;
use ALKO::Mob::Server;

use ALKO::Mob::Manager;
use ALKO::Mob::News;
use ALKO::Mob::Tag::News;
use ALKO::Mob::Tag;

my $Server = WooF::Server->new(output_t => 'JSON', auth => 0);

=begin nd
Constant: FIREBASE_KEY
	ключ для мобльного приложениея
=cut
use constant {
	FIREBASE_KEY => 'AAAAVdEWbxo:APA91bEThk7yMDGBEjBKgbxmA_w96-q5SbamwVLZs7mRkGxPMyVgJgFxTMI59-1TbZu8I9abeyXaPGwBNDJNQwadbWDGE3C7Y9s3N7SnBYU56EnR63-9pm-TIh2vz_oGhQzUB9ZK7LHT',
};

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
#   action     = send_to
# 	id_news    = 1
$Server->add_handler(SEND_TO => {
	input => {
		allow => ['action', 'id_news'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);
		my $id = 1;

		my $news = ALKO::Mob::News->Get($I->{id_news}) or return $S->fail("NOSUCH: Can\'t get News: no such News($I->{id_news})");

		# Полчаем
		my $tags_ref  = ALKO::Mob::Tag::News->All(id_mob_news => $news->id)->Hash('id_mob_news_tag');
		my $news_tag  = ALKO::Mob::Tag->All(id => [keys %$tags_ref])->List;

		my $app_key   = FIREBASE_KEY;
		my $send_text = $news->title;

		for my $tag (@$news_tag) {
			my $param = {
				to => '/topics/'.$tag->name,
				notification => {
					body  => $send_text ,
					title => '#'.$tag->name
				},
				priority => 1
			};

			my $json_param = JSON->new->utf8->encode($param);

			my $send_cmd = "curl -X POST --header 'Authorization: key=$app_key' --Header 'Content-Type: application/json' https://fcm.googleapis.com/fcm/send -d '$json_param'";

			`$send_cmd`;
		}

		OK;
	},
});


# Получить данные представителя магазина
#
# GET
# URL: /?
#   action     = send_all
# 	id_news    = 1
#
$Server->add_handler(SEND_ALL => {
	input => {
		allow => ['action', 'id_news'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $news      = ALKO::Mob::News->Get($I->{id_news}) or return $S->fail("NOSUCH: Can\'t get News: no such News($I->{id_news})");
		my $app_key   = FIREBASE_KEY;
		my $send_text = $news->title;

		my $param = {
			to => '/topics/all',
			notification => {
				body  => $send_text,
				title => 'Для всех'
			},
			priority => 1
		};

		my $json_param =  JSON->new->utf8->encode($param);

		my $send_cmd = "curl -X POST --header 'Authorization: key=$app_key' --Header 'Content-Type: application/json' --Header 'charset:UTF-8' https://fcm.googleapis.com/fcm/send -d '$json_param'";

		`$send_cmd`;

		OK;
	},
});


$Server->dispatcher(sub {
	my $S = shift;
	my $I = $S->I;
	debug  $I;
	return ['SEND_TO']  if exists $I->{action} and $I->{action} eq 'send_to';
	return ['SEND_ALL'] if exists $I->{action} and $I->{action} eq 'send_all';

	['DEFAULT'];
});


$Server->listen;
