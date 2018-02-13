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

		$O->{manager_list} = ALKO::Mob::Manager->All->List;		 
 
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
			manager => [qw/ password email phone name id/],
		],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		if ($I->{manager}{id}) {
			my $manager = ALKO::Mob::Manager->Get($I->{manager}{id}) or return $S->fail("NOSUCH: Can\'t get Manager: no such manager(id => $I->{manager}{id})");
			$manager->password($I->{manager}{password});
			$manager->email($I->{manager}{email});
			$manager->phone($I->{manager}{phone});
			$manager->name($I->{manager}{name});
		} else {			
			ALKO::Mob::Manager->new({
				password => $I->{manager}{password},
				email    => $I->{manager}{email},
				phone    => $I->{manager}{phone},
				name     => $I->{manager}{name},			 
			}); 	
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
