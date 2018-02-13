#! /usr/bin/perl
#
# Homepage
#

use strict;
use warnings;

use WooF::Debug;
use DateTime;
use ALKO::Mob::Server;
use ALKO::File;
use ALKO::Mob::News::Favorite;

use ALKO::Mob::News;

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

		$O->{news_list} = ALKO::Mob::News->All->List;

		OK;
	},
});

# Сбросить пароль
#
# GET
# URL: /?
#   action = add
#   news.title       = String
#	news.text        = String
#   news.description = String
#
$Server->add_handler(ADD => {
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $news;		
		if ($I->{news}{id}) {
			$news = ALKO::Mob::News->Get($I->{news}{id}) or return $S->fail("NOSUCH: Can\'t get News: no such news(id => $I->{news}{id})");
			$news->title($I->{news}{title});
			$news->text($I->{news}{text});
			$news->description($I->{news}{description});
		} else {
			$news = ALKO::Mob::News->new({
				title       => $I->{news}{title},
				text        => $I->{news}{text},
				description => $I->{news}{description},
				ctime       => DateTime->now,
			})->Save;
		} 		 

		if ($I->{upload}) {
			my $path = "$ENV{PWD}/files/news/";
			
			my $file = ALKO::File->new({
				path   => $path,
				upload => $I->{upload},
				name   => $news->id
			});

			my $file_name = $file->upload_file;
			$news->img($file_name);
		}

		OK;
	},
});


# Сбросить пароль
#
# GET
# URL: /?
#   action = add
#   news.title       = String
#	news.text        = String
#   news.description = String
#
$Server->add_handler(DELETE => {
	input => {
		allow => [
			'action',
			news => [qw/ id /],
		],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $news = ALKO::Mob::News->Get($I->{news}{id}) or return $S->fail("NOSUCH: Can\'t get News: no such news(id => $I->{news}{id})");

		my $favorite = ALKO::Mob::News::Favorite->All(id_mob_news => $news->id)->List;

		$_->Remove for @$favorite; 

		$news->Remove;

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
