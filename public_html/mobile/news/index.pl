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
	 

		$O->{news_list} = ALKO::Mob::News->All(ctime => {'>=', $dt_weak->ymd})->List  if $sort eq 'week'; 
		$O->{news_list} = ALKO::Mob::News->All(ctime => {'>=', $dt_month->ymd})->List if $sort eq 'month'; 
		$O->{news_list} = ALKO::Mob::News->All(ctime => {'>=', $dt_year->ymd})->List  if $sort eq 'year'; 
		$O->{news_list} = ALKO::Mob::News->All(ctime => {'>=', $dt_month->ymd})->List if $sort eq 'favorite'; 
		$O->{news_list} = ALKO::Mob::News->All(ctime => {'>=', $dt_month->ymd})->List unless $sort;	 
 
		OK;
	},
});
 

$Server->dispatcher(sub {
	my $S = shift;
	my $I = $S->I;
	debug $I;
	return ['LIST'] if exists $I->{action} and $I->{action} eq 'list';
 

	['DEFAULT'];
});


$Server->listen;
