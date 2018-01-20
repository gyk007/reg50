#! /usr/bin/perl
#
# Homepage
#

use strict;
use warnings;

use WooF::Debug;
use DateTime;
use ALKO::Server;
use ALKO::SendMail qw(send_mail);
use ALKO::Client::Merchant;
use ALKO::RegistrationSession;
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
#   action       = send_mail
#   name         = string
#   email        = string
#   phone        = string
#   name_yr      = string  
#   inn          = string
#   kpp          = string
#   yr_adr       = string
#   adr_podr     = string
#   reg_num      = string
#   date_end_reg = string
#
$Server->add_handler(SEND_MAIL => {
	input => {
		allow => ['action', 'name', 'email', 'phone', 'name_yr', 'inn', 'kpp', 'yr_adr', 'adr_podr', 'reg_num', 'date_end_reg'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		send_mail({
			template => 'new_client',
			subject  => 'REG50 Регистрация',
			info     => $I
		});

		OK;
	},
});

# Сбросить пароль
#
# GET
# URL: /?
#   action = forget_password
#   email  = string
#
$Server->add_handler(FORGET_PASSWORD => {
	input => {
		allow => ['action', 'email'],
	},
	call => sub {
		my $S = shift;
		my ($I, $O) = ($S->I, $S->O);

		my $ctime = DateTime->now;
		my $dtime = DateTime->now->add(days => 2);

		my $merchant = ALKO::Client::Merchant->Get(email => $I->{email}) or return $S->fail("NOSUCH: Can\'t get Merchant: no such merchant(email => $I->{email})");
		# Сбрасываем пароль
		$merchant->password(undef);

		# Удаляем старые сессии
		my $old_reg_session = ALKO::RegistrationSession->All(id_merchant => $merchant->id)->List;
		$_->Remove for @$old_reg_session;
		my $old_session = ALKO::Session->All(id_merchant => $merchant->id)->List;
		$_->Remove for @$old_session;

		# Создаем токен
		my $token;
		my @all = split(//, 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890');
		map { $token .= $all[rand @all]; } (0..14);

		# Создаем сессию для регистрации
		ALKO::RegistrationSession->new({
			token       => $token,
			id_merchant => $merchant->id,
			ctime       => $ctime,
			dtime       => $dtime,
			count       => 1
		})->Save;

		#  Данные для Email
		my $email_data->{token} = $token;

		send_mail({
			template => 'forget_passsword',
			to       => $merchant->email,
			subject  => 'REG50 Сброс пароля',
			info     => $email_data
		});

		$O->{email} = $merchant->email;

		OK;
	},
});

$Server->dispatcher(sub {
	my $S = shift;
	my $I = $S->I;

	return ['SEND_MAIL']       if exists $I->{action} and $I->{action} eq 'send_mail';
	return ['FORGET_PASSWORD'] if exists $I->{action} and $I->{action} eq 'forget_password';

	['DEFAULT'];
});


$Server->listen;
