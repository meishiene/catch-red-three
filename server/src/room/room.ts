import { RoomState, RoomPlayerInfo } from '../types/events';

export interface RoomPlayer {
  id: string;
  name: string;
  socketId: string;
  seatIndex: number;
  isConnected: boolean;
  isAI: boolean;
}

export class Room {
  code: string;
  hostPlayerId: string;
  maxPlayers: number;
  status: 'waiting' | 'playing' | 'finished';
  players: RoomPlayer[];
  createdAt: number;
  lastActivityAt: number;

  constructor(code: string, maxPlayers: number) {
    this.code = code;
    this.maxPlayers = maxPlayers;
    this.status = 'waiting';
    this.players = [];
    this.createdAt = Date.now();
    this.lastActivityAt = Date.now();
    this.hostPlayerId = '';
  }

  addPlayer(player: RoomPlayer): void {
    if (this.players.length === 0) {
      this.hostPlayerId = player.id;
    }
    this.players.push(player);
    this.lastActivityAt = Date.now();
  }

  removePlayer(playerId: string): RoomPlayer | null {
    const index = this.players.findIndex((p) => p.id === playerId);
    if (index === -1) return null;

    const removed = this.players.splice(index, 1)[0];

    if (this.players.length > 0 && this.hostPlayerId === playerId) {
      this.hostPlayerId = this.players[0].id;
    }

    this.lastActivityAt = Date.now();
    return removed;
  }

  getPlayer(playerId: string): RoomPlayer | undefined {
    return this.players.find((p) => p.id === playerId);
  }

  isFull(): boolean {
    return this.players.length >= this.maxPlayers;
  }

  isEmpty(): boolean {
    return this.players.length === 0;
  }

  allConnected(): boolean {
    return this.players.every((p) => p.isConnected || p.isAI);
  }

  getHumanPlayers(): RoomPlayer[] {
    return this.players.filter((p) => !p.isAI);
  }

  toState(): RoomState {
    return {
      code: this.code,
      hostPlayerId: this.hostPlayerId,
      maxPlayers: this.maxPlayers,
      status: this.status,
      players: this.players.map((p) => ({
        id: p.id,
        name: p.name,
        seatIndex: p.seatIndex,
        isConnected: p.isConnected,
        isAI: p.isAI,
      })),
    };
  }
}
