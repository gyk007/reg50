#! /usr/bin/perl
#
# Список клиентов.
# В зависимости от входных параметров меняется состав вывода.
#

use strict;
use warnings;
use WooF::Debug;
use WooF::Server;
use ALKO::Client;

my $Server = WooF::Server->new(output_t => 'JSON');

# Добавить клиента
#
# POST
# URL: /client/?
#   action=add
#   client.name=Perekrestok
#   client.agent=Sergeev Sergei Sergeevich
#   client.address=Address
#   client.phone=89645436
#   client.email=mail@gmail.com
$Server->add_handler(ADD => {
	input => {
		allow => ['action', client => [qw/ name agent address phone email /]],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);
		debug $I->{client};
		my $client = ALKO::Client->new($I->{client}) or return $S->fail('Can\'t create a new client');
		$client->Save or return $S->fail('Can\'t save client');

		$O->{client} = $client->id;

		OK;
	},
});

# Список всех клиентов
# URL: /client/
$Server->add_handler(CLIENTS => {
	call => sub {
		my $S = shift;

		$S->O->{clients} = ALKO::Client->All->List ;

		OK;
	},
});

# Удалить указанного клиента
# URL: /client/?action=delete&id=25
$Server->add_handler(DELETE => {
	input => {
		allow => [qw/ action id /],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		# удаляем клиента
		ALKO::Client->Get(id => $I->{id})->Remove;

		OK;
	},
});


$Server->dispatcher(sub {
	my $S = shift;
	my $I = $S->I;
	return ['ADD']    if exists $I->{action} and $I->{action} eq 'add';
	return ['DELETE'] if exists $I->{action} and $I->{action} eq 'delete';

	return [qw/ CLIENTS /];
});

$Server->listen;
