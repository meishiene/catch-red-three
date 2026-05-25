import { Socket } from 'socket.io';
import { roomManager } from '../../room/room-manager';
import { gameManager } from '../../game/game-manager';

function generateId(): string {
  return Math.random().toString(36).substring(2) + Date.now().toString(36);
}

export function registerConnectionHandlers(socket: Socket): void {
  socket.data.playerId = generateId();
  socket.data.roomCode = null;

  socket.on('disconnect', () => {
    const playerId = socket.data.playerId;
    const roomCode = socket.data.roomCode;

    if (roomCode) {
      const room = roomManager.getRoom(roomCode);
      if (room) {
        const player = room.getPlayer(playerId);
        if (player) {
          player.isConnected = false;
        }
        socket.to(roomCode).emit('room:player-left', { playerId });
      }
    }
  });

  socket.on('reconnect', (data: { playerId: string; roomCode: string }, ack) => {
    const { playerId, roomCode } = data;
    const room = roomManager.getRoom(roomCode);
    if (!room) return ack?.({ error: '房间不存在' });

    const player = room.getPlayer(playerId);
    if (!player) return ack?.({ error: '玩家不在房间中' });

    // Update socket reference
    player.socketId = socket.id;
    player.isConnected = true;
    socket.data.playerId = playerId;
    socket.data.roomCode = roomCode;
    socket.join(roomCode);

    const game = gameManager.getGame(roomCode);
    if (game) {
      const snapshot = game.getSnapshot(playerId);
      ack?.({ success: true, snapshot });
    } else {
      ack?.({ success: true, snapshot: null });
    }
  });
}
