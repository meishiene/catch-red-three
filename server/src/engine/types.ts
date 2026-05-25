export enum Suit {
  SPADE = 'S',
  HEART = 'H',
  CLUB = 'C',
  DIAMOND = 'D',
  JOKER = 'JOKER',
}

export enum Rank {
  FIVE = 5,
  SIX = 6,
  SEVEN = 7,
  EIGHT = 8,
  NINE = 9,
  TEN = 10,
  JACK = 11,
  QUEEN = 12,
  KING = 13,
  ACE = 14,
  TWO = 15,
  THREE = 16,
  FOUR = 17,
  SMALL_JOKER = 18,
  BIG_JOKER = 19,
}

export interface Card {
  id: string;
  suit: Suit;
  rank: Rank;
  isRevealed: boolean;
}

export enum PlayType {
  SINGLE = 'SINGLE',
  PAIR = 'PAIR',
  BOMB = 'BOMB',
  BIG_BOMB = 'BIG_BOMB',
  JOKER_BOMB = 'JOKER_BOMB',
}

export interface PlayInfo {
  type: PlayType;
  value: number;
}

export type Team = 'red' | 'black';

export enum GamePhase {
  WAITING = 'WAITING',
  DEALING = 'DEALING',
  TRIBUTE = 'TRIBUTE',
  IDENTITY_REVEAL = 'IDENTITY_REVEAL',
  PLAYING = 'PLAYING',
  GAME_OVER = 'GAME_OVER',
}

export interface TrickState {
  boardCards: Card[];
  boardPlay: PlayInfo | null;
  boardPlayerId: string | null;
  activePlayerIds: Set<string>;
  playerOrder: string[];
  currentPlayerIndex: number;
  isFirstTrick: boolean;
}

export interface GameResult {
  winner: Team | 'draw';
  finishOrder: { playerId: string; position: number }[];
  redTeam: { playerId: string; isCaught: boolean }[];
  blackTeam: { playerId: string; isCaught: boolean }[];
  firstFinisherId: string;
  caughtPlayerId: string | null;
}

export interface BoardState {
  cards: Card[];
  playType: PlayType;
  playedByPlayerId: string;
  isNewTrick: boolean;
}

export interface TributePair {
  fromPlayerId: string;
  toPlayerId: string;
  cardFromLoser?: Card;
  cardFromWinner?: Card;
}
