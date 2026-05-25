import { Card, PlayInfo, PlayType, Rank, Suit } from './types';
import { PLAY_TYPE_STRENGTH, RANK_POWER, REVEALED_RED_THREE_POWER } from './constants';

export function createCard(suit: Suit, rank: Rank): Card {
  const id = `${suit}_${rank}`;
  return { id, suit, rank, isRevealed: false };
}

export function getSingleCardPower(card: Card): number {
  if (card.suit === Suit.JOKER) {
    return card.rank === Rank.BIG_JOKER ? RANK_POWER[Rank.BIG_JOKER] : RANK_POWER[Rank.SMALL_JOKER];
  }

  if (
    card.isRevealed &&
    (card.suit === Suit.HEART || card.suit === Suit.DIAMOND) &&
    card.rank === Rank.THREE
  ) {
    return REVEALED_RED_THREE_POWER;
  }

  return RANK_POWER[card.rank];
}

export function determinePlay(cards: Card[]): PlayInfo | null {
  const n = cards.length;
  if (n === 0) return null;

  if (n === 1) {
    return { type: PlayType.SINGLE, value: getSingleCardPower(cards[0]) };
  }

  if (n === 2) {
    const jokers = cards.filter((c) => c.suit === Suit.JOKER);
    if (jokers.length === 2) {
      return { type: PlayType.JOKER_BOMB, value: 999 };
    }
    if (
      cards[0].rank === cards[1].rank &&
      cards.every((c) => c.suit !== Suit.JOKER)
    ) {
      return { type: PlayType.PAIR, value: getSingleCardPower(cards[0]) };
    }
    return null;
  }

  if (n === 3) {
    const firstRank = cards[0].rank;
    if (cards.every((c) => c.rank === firstRank && c.suit !== Suit.JOKER)) {
      return { type: PlayType.BOMB, value: getSingleCardPower(cards[0]) };
    }
    return null;
  }

  if (n === 4) {
    const firstRank = cards[0].rank;
    if (cards.every((c) => c.rank === firstRank && c.suit !== Suit.JOKER)) {
      return { type: PlayType.BIG_BOMB, value: getSingleCardPower(cards[0]) };
    }
    return null;
  }

  return null;
}

export function canBeat(
  newPlay: PlayInfo,
  boardPlay: PlayInfo | null
): boolean {
  if (boardPlay === null) return true;

  if (newPlay.type === PlayType.JOKER_BOMB) return true;
  if (boardPlay.type === PlayType.JOKER_BOMB) return false;

  const newStrength = PLAY_TYPE_STRENGTH[newPlay.type];
  const boardStrength = PLAY_TYPE_STRENGTH[boardPlay.type];

  if (newStrength > boardStrength) return true;

  if (newStrength === boardStrength) {
    if (newPlay.type !== boardPlay.type) return false;
    return newPlay.value > boardPlay.value;
  }

  return false;
}

export function isValidOpeningPlay(hand: Card[], selectedCards: Card[]): boolean {
  const hasRedFive = selectedCards.some(
    (c) => c.suit === Suit.HEART && c.rank === Rank.FIVE
  );
  if (!hasRedFive) return false;

  if (!selectedCards.every((c) => c.rank === Rank.FIVE)) return false;

  const handIds = new Set(hand.map((c) => c.id));
  if (!selectedCards.every((c) => handIds.has(c.id))) return false;

  const play = determinePlay(selectedCards);
  return play !== null;
}

export function getHighestCardPower(hand: Card[]): number {
  if (hand.length === 0) return 0;
  return Math.max(...hand.map((c) => getSingleCardPower(c)));
}

export function findHighestCard(hand: Card[]): Card | null {
  if (hand.length === 0) return null;
  return hand.reduce((max, c) =>
    getSingleCardPower(c) > getSingleCardPower(max) ? c : max
  );
}

export function getRevealEligibility(
  hand: Card[],
  maxPlayers: number
): { mustReveal: Card[]; canReveal: Card[] } {
  const result: { mustReveal: Card[]; canReveal: Card[] } = {
    mustReveal: [],
    canReveal: [],
  };

  for (const card of hand) {
    if (card.rank !== Rank.THREE) continue;

    if (card.suit === Suit.HEART) {
      result.canReveal.push(card);
    }
    if (card.suit === Suit.DIAMOND) {
      if (maxPlayers === 5) {
        result.mustReveal.push(card);
      } else if (maxPlayers === 4) {
        result.canReveal.push(card);
      }
      // In 3-player mode, 方片3 is not a red team card, so no reveal needed
    }
  }

  return result;
}

export function applyReveal(hand: Card[], revealedCardIds: string[]): void {
  for (const card of hand) {
    if (revealedCardIds.includes(card.id)) {
      card.isRevealed = true;
    }
  }
}

export function compareCardsDesc(a: Card, b: Card): number {
  const powerDiff = getSingleCardPower(b) - getSingleCardPower(a);
  if (powerDiff !== 0) return powerDiff;
  const suitOrder: Record<string, number> = { S: 3, H: 2, C: 1, D: 0, JOKER: -1 };
  return (suitOrder[b.suit] || 0) - (suitOrder[a.suit] || 0);
}

export function sortHand(hand: Card[]): Card[] {
  return [...hand].sort(compareCardsDesc);
}

export function getCardDisplayName(card: Card): string {
  if (card.suit === Suit.JOKER) {
    return card.rank === Rank.BIG_JOKER ? '大王' : '小王';
  }
  const suitNames: Record<string, string> = { S: '♠', H: '♥', C: '♣', D: '♦' };
  const rankNames: Record<number, string> = {
    5: '5', 6: '6', 7: '7', 8: '8', 9: '9', 10: '10',
    11: 'J', 12: 'Q', 13: 'K', 14: 'A', 15: '2', 16: '3', 17: '4',
  };
  return `${suitNames[card.suit] || ''}${rankNames[card.rank] || card.rank}`;
}
