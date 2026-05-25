import { PlayType, Rank, Suit } from './types';

export const PLAY_TYPE_STRENGTH: Record<PlayType, number> = {
  [PlayType.SINGLE]: 1,
  [PlayType.PAIR]: 1,
  [PlayType.BOMB]: 3,
  [PlayType.BIG_BOMB]: 4,
  [PlayType.JOKER_BOMB]: 5,
};

export const RANK_POWER: Record<Rank, number> = {
  [Rank.FIVE]: 5,
  [Rank.SIX]: 6,
  [Rank.SEVEN]: 7,
  [Rank.EIGHT]: 8,
  [Rank.NINE]: 9,
  [Rank.TEN]: 10,
  [Rank.JACK]: 11,
  [Rank.QUEEN]: 12,
  [Rank.KING]: 13,
  [Rank.ACE]: 14,
  [Rank.TWO]: 15,
  [Rank.THREE]: 16,
  [Rank.FOUR]: 17,
  [Rank.SMALL_JOKER]: 18,
  [Rank.BIG_JOKER]: 19,
};

export const REVEALED_RED_THREE_POWER = 17.5;

export const SUIT_ORDER: Record<Suit, number> = {
  [Suit.SPADE]: 3,
  [Suit.HEART]: 2,
  [Suit.CLUB]: 1,
  [Suit.DIAMOND]: 0,
  [Suit.JOKER]: -1,
};

export const IDENTITY_REVEAL_TIMEOUT_MS = 15000;
export const TURN_TIMEOUT_MS = 30000;
export const GAME_START_COUNTDOWN_MS = 3000;
