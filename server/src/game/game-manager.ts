import { Server as SocketIOServer } from 'socket.io';
import { GameInstance } from './game-instance';
import { Room } from '../room/room';

export class GameManager {
  private games: Map<string, GameInstance> = new Map();

  createGame(
    room: Room,
    io: SocketIOServer
  ): GameInstance {
    const players = room.players.map((p) => ({
      id: p.id,
      name: p.name,
      isAI: p.isAI,
    }));

    const eventCallback = (event: string, data: any) => {
      // If data has targetPlayerId, send only to that player
      if (data && data.targetPlayerId) {
        const targetPlayer = room.players.find(
          (p) => p.id === data.targetPlayerId
        );
        if (targetPlayer && targetPlayer.socketId) {
          io.to(targetPlayer.socketId).emit(event, data);
          return;
        }
      }
      // Otherwise broadcast to entire room
      io.to(room.code).emit(event, data);
    };

    const game = new GameInstance(
      room.code,
      players,
      room.maxPlayers,
      eventCallback
    );

    this.games.set(room.code, game);
    return game;
  }

  getGame(roomCode: string): GameInstance | undefined {
    return this.games.get(roomCode);
  }

  removeGame(roomCode: string): void {
    this.games.delete(roomCode);
  }
}

export const gameManager = new GameManager();
