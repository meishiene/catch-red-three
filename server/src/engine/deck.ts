import { Card, Rank, Suit } from './types';
import { createCard, compareCardsDesc } from './card';

export function createDeck(): Card[] {
  const suits = [Suit.SPADE, Suit.HEART, Suit.CLUB, Suit.DIAMOND];
  const ranks = [
    Rank.FIVE, Rank.SIX, Rank.SEVEN, Rank.EIGHT, Rank.NINE, Rank.TEN,
    Rank.JACK, Rank.QUEEN, Rank.KING, Rank.ACE, Rank.TWO, Rank.THREE, Rank.FOUR,
  ];

  const deck: Card[] = [];
  for (const suit of suits) {
    for (const rank of ranks) {
      deck.push(createCard(suit, rank));
    }
  }

  deck.push(createCard(Suit.JOKER, Rank.SMALL_JOKER));
  deck.push(createCard(Suit.JOKER, Rank.BIG_JOKER));

  return deck;
}

export function shuffleDeck(deck: Card[]): Card[] {
  const shuffled = [...deck];
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
  }
  return shuffled;
}

export function deal(
  numPlayers: number,
  firstDealtPlayerIndex: number
): Card[][] {
  const deck = shuffleDeck(createDeck());
  const hands: Card[][] = Array.from({ length: numPlayers }, () => []);

  for (let i = 0; i < deck.length; i++) {
    const playerIdx = (firstDealtPlayerIndex + i) % numPlayers;
    hands[playerIdx].push(deck[i]);
  }

  for (const hand of hands) {
    hand.sort(compareCardsDesc);
  }

  return hands;
}

export function findRedFiveHolder(
  hands: Map<string, Card[]>
): string | null {
  for (const [playerId, hand] of hands) {
    const hasRedFive = hand.some(
      (c) => c.suit === Suit.HEART && c.rank === Rank.FIVE
    );
    if (hasRedFive) return playerId;
  }
  return null;
}
