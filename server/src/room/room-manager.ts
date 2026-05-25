import { Room, RoomPlayer } from './room';
import { config } from '../config';

function generateId(): string {
  return Math.random().toString(36).substring(2) + Date.now().toString(36);
}

export class RoomManager {
  private rooms: Map<string, Room> = new Map();
  private playerRoomMap: Map<string, string> = new Map();
  private cleanupInterval: NodeJS.Timeout | null = null;

  createRoom(maxPlayers: number): Room {
    const code = this.generateRoomCode();
    const room = new Room(code, maxPlayers);
    this.rooms.set(code, room);
    return room;
  }

  createRoomWithAI(maxPlayers: number, humanPlayer: RoomPlayer): Room {
    const room = this.createRoom(maxPlayers);
    humanPlayer.seatIndex = 0;
    room.addPlayer(humanPlayer);
    this.playerRoomMap.set(humanPlayer.id, room.code);

    // Fill remaining seats with AI
    for (let i = 1; i < maxPlayers; i++) {
      const aiPlayer: RoomPlayer = {
        id: `ai_${generateId()}`,
        name: `电脑${i}`,
        socketId: '',
        seatIndex: i,
        isConnected: true,
        isAI: true,
      };
      room.addPlayer(aiPlayer);
    }

    return room;
  }

  getRoom(code: string): Room | undefined {
    return this.rooms.get(code);
  }

  joinRoom(code: string, player: RoomPlayer): Room | null {
    const room = this.rooms.get(code);
    if (!room) return null;
    if (room.status !== 'waiting') return null;
    if (room.isFull()) return null;

    player.seatIndex = room.players.length;
    room.addPlayer(player);
    this.playerRoomMap.set(player.id, code);
    return room;
  }

  leaveRoom(playerId: string): Room | null {
    const code = this.playerRoomMap.get(playerId);
    if (!code) return null;

    const room = this.rooms.get(code);
    if (!room) {
      this.playerRoomMap.delete(playerId);
      return null;
    }

    room.removePlayer(playerId);
    this.playerRoomMap.delete(playerId);

    if (room.isEmpty()) {
      this.rooms.delete(code);
    }

    return room;
  }

  getPlayerRoom(playerId: string): Room | undefined {
    const code = this.playerRoomMap.get(playerId);
    if (!code) return undefined;
    return this.rooms.get(code);
  }

  startCleanup(): void {
    this.cleanupInterval = setInterval(() => {
      const now = Date.now();
      for (const [code, room] of this.rooms) {
        if (room.isEmpty() && now - room.lastActivityAt > config.roomMaxIdleMs) {
          this.rooms.delete(code);
        }
        if (room.players.length > 0 && now - room.lastActivityAt > config.roomMaxIdleMs * 2) {
          for (const player of room.players) {
            this.playerRoomMap.delete(player.id);
          }
          this.rooms.delete(code);
        }
      }
    }, config.roomCleanupIntervalMs);
  }

  stopCleanup(): void {
    if (this.cleanupInterval) {
      clearInterval(this.cleanupInterval);
      this.cleanupInterval = null;
    }
  }

  private generateRoomCode(): string {
    let code: string;
    do {
      code = '';
      for (let i = 0; i < config.roomCodeLength; i++) {
        code += config.roomCodeChars[Math.floor(Math.random() * config.roomCodeChars.length)];
      }
    } while (this.rooms.has(code));
    return code;
  }
}

export const roomManager = new RoomManager();
