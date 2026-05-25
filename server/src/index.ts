import { createApp } from './server/app';
import { setupSocketIO } from './socket/setup';
import { roomManager } from './room/room-manager';
import { config } from './config';

const { httpServer } = createApp();
const io = setupSocketIO(httpServer);

roomManager.startCleanup();

httpServer.listen(config.port, config.host, () => {
  console.log(`抓红3 Server running on ${config.host}:${config.port}`);
});

process.on('SIGTERM', () => {
  roomManager.stopCleanup();
  io.close();
  httpServer.close();
});

process.on('SIGINT', () => {
  roomManager.stopCleanup();
  io.close();
  httpServer.close();
});
