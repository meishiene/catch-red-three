import { createDeck, shuffleDeck, deal, findRedFiveHolder } from '../../src/engine/deck';
import { Suit, Rank } from '../../src/engine/types';
import { getSingleCardPower } from '../../src/engine/card';

describe('shuffleDeck', () => {
  it('returns same number of cards', () => {
    const deck = createDeck();
    const shuffled = shuffleDeck(deck);
    expect(shuffled).toHaveLength(54);
  });

  it('contains same cards after shuffle', () => {
    const deck = createDeck();
    const shuffled = shuffleDeck(deck);
    const deckIds = deck.map((c) => c.id).sort();
    const shuffledIds = shuffled.map((c) => c.id).sort();
    expect(shuffledIds).toEqual(deckIds);
  });
});

describe('deal', () => {
  it('deals all 54 cards', () => {
    const hands = deal(3, 0);
    const total = hands.reduce((sum, h) => sum + h.length, 0);
    expect(total).toBe(54);
  });

  it('distributes cards evenly as possible', () => {
    const hands3 = deal(3, 0);
    expect(hands3[0].length).toBe(18);
    expect(hands3[1].length).toBe(18);
    expect(hands3[2].length).toBe(18);

    const hands4 = deal(4, 0);
    const lens4 = hands4.map((h) => h.length);
    expect(Math.max(...lens4) - Math.min(...lens4)).toBeLessThanOrEqual(1);

    const hands5 = deal(5, 0);
    const lens5 = hands5.map((h) => h.length);
    expect(Math.max(...lens5) - Math.min(...lens5)).toBeLessThanOrEqual(1);
  });

  it('first dealt player index works', () => {
    const hands = deal(3, 1);
    // Player 1 gets first card, so they should have 18 cards
    expect(hands[1].length).toBe(18);
  });

  it('hands are sorted', () => {
    const hands = deal(3, 0);
    for (const hand of hands) {
      for (let i = 0; i < hand.length - 1; i++) {
        expect(
          getSingleCardPower(hand[i])
        ).toBeGreaterThanOrEqual(
          getSingleCardPower(hand[i + 1])
        );
      }
    }
  });
});

describe('findRedFiveHolder', () => {
  it('finds the player with 红桃5', () => {
    const hands = new Map<string, import('../../src/engine/types').Card[]>();
    hands.set('p1', [{ id: 'S_5', suit: Suit.SPADE, rank: Rank.FIVE, isRevealed: false }]);
    hands.set('p2', [{ id: 'H_5', suit: Suit.HEART, rank: Rank.FIVE, isRevealed: false }]);
    hands.set('p3', [{ id: 'C_5', suit: Suit.CLUB, rank: Rank.FIVE, isRevealed: false }]);

    expect(findRedFiveHolder(hands)).toBe('p2');
  });

  it('returns null if no one has 红桃5', () => {
    const hands = new Map<string, import('../../src/engine/types').Card[]>();
    hands.set('p1', [{ id: 'S_5', suit: Suit.SPADE, rank: Rank.FIVE, isRevealed: false }]);

    expect(findRedFiveHolder(hands)).toBeNull();
  });
});
