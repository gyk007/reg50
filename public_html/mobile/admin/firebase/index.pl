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
#   id_manager = 1
$Server->add_handler(SEND_TO => {
	input => {
		allow => ['action', 'id_news', 'id_manager'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);
		my $id = 1;
		my $manager = ALKO::Mob::Manager->Get($id) or return $S->fail("NOSUCH: Can\'t get Manager: no such Manager($I->{id_manager})");
		my $news    = ALKO::Mob::News->Get($I->{id_news})       or return $S->fail("NOSUCH: Can\'t get News: no such News($I->{id_news})");

		my $manager_key = $manager->firebase or return $S->fail("NOSUCH: Can\'t get KEY: no such KEY ($I->{id_manager})");
		my $app_key     = FIREBASE_KEY;
		my $send_text   = $news->title;	 	
	 	 
		my $param = {
			to => $manager_key,
			notification => {
				body => $send_text ,
				title => 'Вымпел'
			},
			priority => 1
		};

		my $json_param =  JSON->new->utf8->encode($param);		 

		my $send_cmd = "curl -X POST --header 'Authorization: key=$app_key' --Header 'Content-Type: application/json' https://fcm.googleapis.com/fcm/send -d '$json_param'";	
		 
		`$send_cmd`;
	 
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
				title => 'Вымпел'
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
