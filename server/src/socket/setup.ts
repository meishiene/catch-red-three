import { Server as SocketIOServer } from 'socket.io';
import { Server as HTTPServer } from 'http';
import { registerRoomHandlers } from './handlers/room.handler';
import { registerGameHandlers } from './handlers/game.handler';
import { registerConnectionHandlers } from './handlers/connection.handler';
import { config } from '../config';

export function setupSocketIO(httpServer: HTTPServer): SocketIOServer {
  const io = new SocketIOServer(httpServer, {
    cors: {
      origin: config.corsOrigin,
      methods: ['GET', 'POST'],
    },
    pingTimeout: 60000,
    pingInterval: 25000,
  });

  io.on('connection', (socket) => {
    registerConnectionHandlers(socket);
    registerRoomHandlers(socket, io);
    registerGameHandlers(socket);
  });

  return io;
}
