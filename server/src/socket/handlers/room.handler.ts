import { Socket } from 'socket.io';
import { roomManager } from '../../room/room-manager';
import { gameManager } from '../../game/game-manager';
import { C2S, S2C } from '../../types/events';

export function registerRoomHandlers(socket: Socket, io: any): void {
  socket.on(C2S.ROOM_CREATE, (data: { playerName: string; maxPlayers: number }, ack) => {
    try {
      if (!data.playerName || !data.maxPlayers) {
        return ack?.({ error: '参数不完整' });
      }
      if (![3, 4, 5].includes(data.maxPlayers)) {
        return ack?.({ error: '人数必须为3/4/5' });
      }

      const room = roomManager.createRoom(data.maxPlayers);
      const player = {
        id: socket.data.playerId,
        name: data.playerName,
        socketId: socket.id,
        seatIndex: 0,
        isConnected: true,
        isAI: false,
      };
      room.addPlayer(player);

      socket.data.roomCode = room.code;
      socket.join(room.code);

      ack?.({ roomCode: room.code, playerId: player.id, room: room.toState() });
    } catch (e: any) {
      ack?.({ error: e.message });
    }
  });

  socket.on(C2S.ROOM_JOIN, (data: { roomCode: string; playerName: string }, ack) => {
    try {
      if (!data.roomCode || !data.playerName) {
        return ack?.({ error: '参数不完整' });
      }

      const code = data.roomCode.toUpperCase();
      const room = roomManager.getRoom(code);

      if (!room) return ack?.({ error: '房间不存在' });
      if (room.status !== 'waiting') return ack?.({ error: '游戏已开始' });
      if (room.isFull()) return ack?.({ error: '房间已满' });

      const player = {
        id: socket.data.playerId,
        name: data.playerName,
        socketId: socket.id,
        seatIndex: 0,
        isConnected: true,
        isAI: false,
      };

      const joined = roomManager.joinRoom(code, player);
      if (!joined) return ack?.({ error: '加入失败' });

      socket.data.roomCode = code;
      socket.join(code);

      ack?.({ playerId: player.id, room: room.toState() });
      io.to(code).emit(S2C.ROOM_UPDATED, room.toState());
    } catch (e: any) {
      ack?.({ error: e.message });
    }
  });

  socket.on(C2S.ROOM_LEAVE, () => {
    const playerId = socket.data.playerId;
    const room = roomManager.leaveRoom(playerId);

    if (room) {
      const code = room.code;
      socket.leave(code);
      socket.data.roomCode = null;
      io.to(code).emit(S2C.ROOM_UPDATED, room.toState());
      if (room.isEmpty()) {
        gameManager.removeGame(code);
      }
    }
  });

  socket.on(C2S.ROOM_START, (_data, ack) => {
    const playerId = socket.data.playerId;
    const roomCode = socket.data.roomCode;
    if (!roomCode) return ack?.({ error: '不在房间中' });

    const room = roomManager.getRoom(roomCode);
    if (!room) return ack?.({ error: '房间不存在' });
    if (room.hostPlayerId !== playerId) return ack?.({ error: '只有房主可以开始' });
    if (room.players.length < 3) return ack?.({ error: '至少需要3人' });

    room.status = 'playing';

    const game = gameManager.createGame(room, io);
    game.start();

    ack?.({ success: true });
  });
}
