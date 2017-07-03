# Переопледеляем Proc::Daemon
# так, чтобы в случае exec_command можно было передать work_dir
# для каждого запускаемого скрипта

package ALKO::ProcDaemon;

use parent 'Proc::Daemon';

use strict;
use warnings;

use POSIX();

=begin nd
Method: Init ( )
	Используется наш дополнительный член класса 'cwdir'.
=cut
sub Init {
    my ALKO::ProcDaemon $self = shift;
    my $settings_ref = shift;


    # Check if $self has been blessed into the package, otherwise do it now.
    unless ( ref( $self ) && eval{ $self->isa( 'Proc::Daemon' ) } ) {
        $self = ref( $self ) eq 'HASH' ? Proc::Daemon->new( %$self ) : Proc::Daemon->new();
    }
    # If $daemon->Init is used again in the same script,
    # update to the new arguments.
    elsif ( ref( $settings_ref ) eq 'HASH' ) {
        map { $self->{ $_ } = $$settings_ref{ $_ } } keys %$settings_ref;
    }


    # Open a filehandle to an anonymous temporary pid file. If this is not
    # possible (some environments do not allow all users to use anonymous
    # temporary files), use the pid_file(s) to retrieve the PIDs for the parent.
    my $FH_MEMORY;
    unless ( open( $FH_MEMORY, "+>", undef ) || $self->{pid_file} ) {
        die "Can not <open> anonymous temporary pidfile ('$!'), therefore you must add 'pid_file' as an Init() argument, e.g. to: '/tmp/proc_daemon_pids'";
    }


    # Get the file descriptors the user does not want to close.
    my %dont_close_fd;
    if ( defined $self->{dont_close_fd} ) {
        die "The argument 'dont_close_fd' must be arrayref!"
            if ref( $self->{dont_close_fd} ) ne 'ARRAY';
        foreach ( @{ $self->{dont_close_fd} } ) {
            die "All entries in 'dont_close_fd' must be numeric ('$_')!" if $_ =~ /\D/;
            $dont_close_fd{ $_ } = 1;
        }
    }
    # Get the file descriptors of the handles the user does not want to close.
    if ( defined $self->{dont_close_fh} ) {
        die "The argument 'dont_close_fh' must be arrayref!"
            if ref( $self->{dont_close_fh} ) ne 'ARRAY';
        foreach ( @{ $self->{dont_close_fh} } ) {
            if ( defined ( my $fn = fileno $_ ) ) {
                $dont_close_fd{ $fn } = 1;
            }
        }
    }


    # If system commands are to be executed, put them in a list.
    my @exec_command = ref( $self->{exec_command} ) eq 'ARRAY' ? @{ $self->{exec_command} } : ( $self->{exec_command} );
    $#exec_command = 0 if $#exec_command < 0;


    # Create a daemon for every system command.
    foreach my $exec_command ( @exec_command ) {
        # The first parent is running here.


        # Using this subroutine or loop multiple times we must modify the filenames:
        # 'child_STDIN', 'child_STDOUT', 'child_STDERR' and 'pid_file' for every
        # daemon (a higher number will be appended to the filenames).
        $self->adjust_settings();


        # First fork.
        my $pid = $self->Fork();
        if ( defined $pid && $pid == 0 ) {
            # The first child runs here.

            # ALKO: каждый раз вытаскиваем следующую рабочую диру, пока они не кончатся.
            # Как закончатся, для всех последующих скриптов будет установлена последняя дира в переданном массиве.
            if (exists $self->{cwdir}) {
		my $cwdir = $self->{cwdir};
		$self->{work_dir} = shift @$cwdir if @$cwdir;
            }
            
            # Set the new working directory.
            die "Can't <chdir> to $self->{work_dir}: $!" unless chdir $self->{work_dir};

            # Set the file creation mask.
            $self->{_orig_umask} = umask;
            umask($self->{file_umask});

            # Detach the child from the terminal (no controlling tty), make it the
            # session-leader and the process-group-leader of a new process group.
            die "Cannot detach from controlling terminal" if POSIX::setsid() < 0;

            # "Is ignoring SIGHUP necessary?
            #
            # It's often suggested that the SIGHUP signal should be ignored before
            # the second fork to avoid premature termination of the process. The
            # reason is that when the first child terminates, all processes, e.g.
            # the second child, in the orphaned group will be sent a SIGHUP.
            #
            # 'However, as part of the session management system, there are exactly
            # two cases where SIGHUP is sent on the death of a process:
            #
            #   1) When the process that dies is the session leader of a session that
            #      is attached to a terminal device, SIGHUP is sent to all processes
            #      in the foreground process group of that terminal device.
            #   2) When the death of a process causes a process group to become
            #      orphaned, and one or more processes in the orphaned group are
            #      stopped, then SIGHUP and SIGCONT are sent to all members of the
            #      orphaned group.' [2]
            #
            # The first case can be ignored since the child is guaranteed not to have
            # a controlling terminal. The second case isn't so easy to dismiss.
            # The process group is orphaned when the first child terminates and
            # POSIX.1 requires that every STOPPED process in an orphaned process
            # group be sent a SIGHUP signal followed by a SIGCONT signal. Since the
            # second child is not STOPPED though, we can safely forego ignoring the
            # SIGHUP signal. In any case, there are no ill-effects if it is ignored."
            # Source: http://code.activestate.com/recipes/278731/
            #
           # local $SIG{'HUP'} = 'IGNORE';

            # Second fork.
            # This second fork is not absolutely necessary, it is more a precaution.
            # 1. Prevent possibility of reacquiring a controlling terminal.
            # Without this fork the daemon would remain a session-leader. In
            # this case there is a potential possibility that the process could
            # reacquire a controlling terminal. E.g. if it opens a terminal device,
            # without using the O_NOCTTY flag. In Perl this is normally the case
            # when you use <open> on this kind of device, instead of <sysopen>
            # with the O_NOCTTY flag set.
            # Note: Because of the second fork the daemon will not be a session-
            # leader and therefore Signals will not be send to other members of
            # his process group. If you need the functionality of a session-leader
            # you may want to call POSIX::setsid() manually on your daemon.
            # 2. Detach the daemon completely from the parent.
            # The double-fork prevents the daemon from becoming a zombie. It is
            # needed in this module because the grandparent process can continue.
            # Without the second fork and if a child exits before the parent
            # and you forget to call <wait> in the parent you will get a zombie
            # until the parent also terminates. Using the second fork we can be
            # sure that the parent of the daemon is finished near by or before
            # the daemon exits.
            $pid = $self->Fork();
            if ( defined $pid && $pid == 0 ) {
                # Here the second child is running.


                # Close all file handles and descriptors the user does not want
                # to preserve.
                my $hc_fd; # highest closed file descriptor
                close $FH_MEMORY;
                foreach ( 0 .. OpenMax() ) {
                    unless ( $dont_close_fd{ $_ } ) {
                        if    ( $_ == 0 ) { close STDIN  }
                        elsif ( $_ == 1 ) { close STDOUT }
                        elsif ( $_ == 2 ) { close STDERR }
                        else { $hc_fd = $_ if POSIX::close( $_ ) }
                    }
                }

                # Sets the real group identifier and the effective group
                # identifier for the daemon process before opening files.
                # Must set group first because you cannot change group
                # once you have changed user
                POSIX::setgid( $self->{setgid} ) if defined $self->{setgid};

                # Sets the real user identifier and the effective user
                # identifier for the daemon process before opening files.
                POSIX::setuid( $self->{setuid} ) if defined $self->{setuid};

                # Reopen STDIN, STDOUT and STDERR to 'child_STD...'-path or to
                # /dev/null. Data written on a null special file is discarded.
                # Reads from the null special file always return end of file.
                open( STDIN,  $self->{child_STDIN}  || "</dev/null" )  unless $dont_close_fd{ 0 };
                open( STDOUT, $self->{child_STDOUT} || "+>/dev/null" ) unless $dont_close_fd{ 1 };
                open( STDERR, $self->{child_STDERR} || "+>/dev/null" ) unless $dont_close_fd{ 2 };

                # Since <POSIX::close(FD)> is in some cases "secretly" closing
                # file descriptors without telling it to perl, we need to
                # re<open> and <CORE::close(FH)> as many files as we closed with
                # <POSIX::close(FD)>. Otherwise it can happen (especially with
                # FH opened by __DATA__ or __END__) that there will be two perl
                # handles associated with one file, what can cause some
                # confusion.   :-)
                # see: http://rt.perl.org/rt3/Ticket/Display.html?id=72526
                if ( $hc_fd ) {
                    my @fh;
                    foreach ( 3 .. $hc_fd ) { open $fh[ $_ ], "</dev/null" }
                    # Perl will try to close all handles when @fh leaves scope
                    # here, but the rude ones will sacrifice themselves to avoid
                    # potential damage later.
                }

                # Restore the original file creation mask.
                umask $self->{_orig_umask};

                # Execute a system command and never return.
                if ( $exec_command ) {
                    exec ($exec_command) or die "couldn't exec $exec_command: $!";
                    exit; # Not a real exit, but needed since Perl warns you if
                    # there is no statement like <die>, <warn>, or <exit>
                    # following <exec>. The <exec> function executes a system
                    # command and never returns.
                }


                # Return the childs own PID (= 0)
                return $pid;
            }


            # First child (= second parent) runs here.


            # Print the PID of the second child into ...
            $pid ||= '';
            # ... the anonymous temporary pid file.
            if ( $FH_MEMORY ) {
                print $FH_MEMORY "$pid\n";
                close $FH_MEMORY;
            }
            # ... the real 'pid_file'.
            if ( $self->{pid_file} ) {
                open( my $FH_PIDFILE, "+>", $self->{pid_file} ) ||
                    die "Can not open pidfile (pid_file => '$self->{pid_file}'): $!";
                print $FH_PIDFILE $pid;
                close $FH_PIDFILE;
            }


            # Don't <wait> for the second child to exit,
            # even if we don't have a value in $exec_command.
            # The second child will become orphan by <exit> here, but then it
            # will be adopted by init(8), which automatically performs a <wait>
            # to remove the zombie when the child exits.

            POSIX::_exit(0);
        }


        # Only first parent runs here.


        # A child that terminates, but has not been waited for becomes
        # a zombie. So we wait for the first child to exit.
        waitpid( $pid, 0 );
    }


    # Only first parent runs here.


    # Exit if the context is looking for no value (void context).
    exit 0 unless defined wantarray;

    # Get the daemon PIDs out of the anonymous temporary pid file
    # or out of the real pid-file(s)
    my @pid;
    if ( $FH_MEMORY ) {
        seek( $FH_MEMORY, 0, 0 );
        @pid = map { chomp $_; $_ eq '' ? undef : $_ } <$FH_MEMORY>;
        $_ = (/^(\d+)$/)[0] foreach @pid; # untaint
        close $FH_MEMORY;
    }
    elsif ( $self->{memory}{pid_file} ) {
        foreach ( keys %{ $self->{memory}{pid_file} } ) {
            open( $FH_MEMORY, "<", $_ ) || die "Can not open pid_file '<$_': $!";
            push( @pid, <$FH_MEMORY> );
            close $FH_MEMORY;
        }
    }

    # Return the daemon PIDs (from second child/ren) to the first parent.
    return ( wantarray ? @pid : $pid[0] );
}

################################################################################
# OpenMax( [ NUMBER ] )
# Returns the maximum number of possible file descriptors. If sysconf()
# does not give me a valid value, I return NUMBER (default is 64).
################################################################################
sub OpenMax {
    my $openmax = POSIX::sysconf( &POSIX::_SC_OPEN_MAX );

    return ( ! defined( $openmax ) || $openmax < 0 ) ?
        ( shift || 64 ) : $openmax;
}

1;
