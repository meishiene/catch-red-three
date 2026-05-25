import { Card, GameResult, Team } from '../engine/types';

// --- Client-to-Server Events ---
export const C2S = {
  ROOM_CREATE: 'room:create',
  ROOM_JOIN: 'room:join',
  ROOM_LEAVE: 'room:leave',
  ROOM_START: 'room:start',
  ROOM_KICK: 'room:kick',
  GAME_REVEAL: 'game:reveal',
  GAME_SKIP_REVEAL: 'game:skip-reveal',
  GAME_PLAY: 'game:play',
  GAME_PASS: 'game:pass',
  GAME_TRIBUTE_RETURN: 'game:tribute-return',
  RECONNECT: 'reconnect',
} as const;

// --- Server-to-Client Events ---
export const S2C = {
  ROOM_UPDATED: 'room:updated',
  ROOM_ERROR: 'room:error',
  ROOM_PLAYER_LEFT: 'room:player-left',
  GAME_STARTING: 'game:starting',
  GAME_DEALT: 'game:dealt',
  GAME_IDENTITY_PHASE: 'game:identity-phase',
  GAME_IDENTITY_REVEALED: 'game:identity-revealed',
  GAME_IDENTITY_PHASE_END: 'game:identity-phase-end',
  GAME_TRIBUTE_PHASE: 'game:tribute-phase',
  GAME_TRIBUTE_COMPLETE: 'game:tribute-complete',
  GAME_TRICK_START: 'game:trick-start',
  GAME_TURN_REQUEST: 'game:turn-request',
  GAME_CARDS_PLAYED: 'game:cards-played',
  GAME_PLAYER_PASSED: 'game:player-passed',
  GAME_TRICK_WON: 'game:trick-won',
  GAME_PLAYER_FINISHED: 'game:player-finished',
  GAME_CARDS_REMAINING: 'game:cards-remaining',
  GAME_OVER: 'game:over',
  GAME_ERROR: 'game:error',
} as const;

// --- Payload Types ---
export interface RoomState {
  code: string;
  hostPlayerId: string;
  maxPlayers: number;
  status: 'waiting' | 'playing' | 'finished';
  players: RoomPlayerInfo[];
}

export interface RoomPlayerInfo {
  id: string;
  name: string;
  seatIndex: number;
  isConnected: boolean;
  isAI: boolean;
}

export interface BoardStatePayload {
  cards: { id: string; suit: string; rank: number; isRevealed: boolean }[];
  playType: string;
  playedByPlayerId: string;
  isNewTrick: boolean;
}

export interface GameStateSnapshot {
  phase: string;
  hand: { id: string; suit: string; rank: number; isRevealed: boolean }[];
  board: BoardStatePayload | null;
  teams: Record<string, Team>;
  revealedCards: { playerId: string; cardId: string }[];
  finishOrder: { playerId: string; position: number }[];
  opponentCardCounts: Record<string, number>;
  currentTurnPlayerId: string | null;
  turnTimeoutRemainingMs: number | null;
  trickLeaderId: string | null;
  isFirstTrick: boolean;
}

export interface GameOverPayload extends GameResult {}
