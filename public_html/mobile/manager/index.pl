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
#
$Server->add_handler(ADD_FIREBASE_TOKEN => {
	input => {
		allow => ['action', 'firebase_token'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);
		
		my $manager = ALKO::Mob::Manager->Get($O->{SESSION}{id_mob_manager}) or return $S->fail("NOSUCH: Can\'t get Manager: no such Manager($O->{SESSION}{id_mob_manager})");
		 
		$manager->firebase($I->{firebase_token}); 
 		
		OK;
	},
});
 

$Server->dispatcher(sub {
	my $S = shift;
	my $I = $S->I;
	debug $I;
	return ['ADD_FIREBASE_TOKEN'] if exists $I->{action} and $I->{action} eq 'add_firebase_token';
 

	['DEFAULT'];
});


$Server->listen;
