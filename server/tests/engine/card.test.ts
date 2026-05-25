import {
  createCard,
  getSingleCardPower,
  determinePlay,
  canBeat,
  isValidOpeningPlay,
  findHighestCard,
  getRevealEligibility,
  applyReveal,
  sortHand,
  compareCardsDesc,
} from '../../src/engine/card';
import { Suit, Rank, PlayType } from '../../src/engine/types';
import { createDeck } from '../../src/engine/deck';

describe('createCard', () => {
  it('creates a card with correct id, suit, rank', () => {
    const card = createCard(Suit.HEART, Rank.THREE);
    expect(card.id).toBe('H_16');
    expect(card.suit).toBe(Suit.HEART);
    expect(card.rank).toBe(Rank.THREE);
    expect(card.isRevealed).toBe(false);
  });

  it('creates joker cards', () => {
    const small = createCard(Suit.JOKER, Rank.SMALL_JOKER);
    const big = createCard(Suit.JOKER, Rank.BIG_JOKER);
    expect(small.suit).toBe(Suit.JOKER);
    expect(big.suit).toBe(Suit.JOKER);
    expect(small.id).toBe('JOKER_18');
    expect(big.id).toBe('JOKER_19');
  });
});

describe('getSingleCardPower', () => {
  it('returns correct power for normal ranks', () => {
    expect(getSingleCardPower(createCard(Suit.SPADE, Rank.FIVE))).toBe(5);
    expect(getSingleCardPower(createCard(Suit.HEART, Rank.TEN))).toBe(10);
    expect(getSingleCardPower(createCard(Suit.CLUB, Rank.ACE))).toBe(14);
    expect(getSingleCardPower(createCard(Suit.DIAMOND, Rank.TWO))).toBe(15);
    expect(getSingleCardPower(createCard(Suit.SPADE, Rank.THREE))).toBe(16);
    expect(getSingleCardPower(createCard(Suit.HEART, Rank.FOUR))).toBe(17);
  });

  it('returns correct power for jokers', () => {
    expect(getSingleCardPower(createCard(Suit.JOKER, Rank.SMALL_JOKER))).toBe(18);
    expect(getSingleCardPower(createCard(Suit.JOKER, Rank.BIG_JOKER))).toBe(19);
  });

  it('returns boosted power for revealed red threes', () => {
    const redThree = createCard(Suit.HEART, Rank.THREE);
    redThree.isRevealed = true;
    expect(getSingleCardPower(redThree)).toBe(17.5);

    const diamondThree = createCard(Suit.DIAMOND, Rank.THREE);
    diamondThree.isRevealed = true;
    expect(getSingleCardPower(diamondThree)).toBe(17.5);
  });

  it('does not boost non-red threes', () => {
    const spadeThree = createCard(Suit.SPADE, Rank.THREE);
    spadeThree.isRevealed = true;
    expect(getSingleCardPower(spadeThree)).toBe(16);
  });
});

describe('determinePlay', () => {
  it('returns null for empty cards', () => {
    expect(determinePlay([])).toBeNull();
  });

  it('identifies SINGLE', () => {
    const result = determinePlay([createCard(Suit.SPADE, Rank.ACE)]);
    expect(result).not.toBeNull();
    expect(result!.type).toBe(PlayType.SINGLE);
    expect(result!.value).toBe(14);
  });

  it('identifies PAIR', () => {
    const pair = [
      createCard(Suit.SPADE, Rank.KING),
      createCard(Suit.HEART, Rank.KING),
    ];
    const result = determinePlay(pair);
    expect(result).not.toBeNull();
    expect(result!.type).toBe(PlayType.PAIR);
    expect(result!.value).toBe(13);
  });

  it('identifies JOKER_BOMB', () => {
    const jokerBomb = [
      createCard(Suit.JOKER, Rank.SMALL_JOKER),
      createCard(Suit.JOKER, Rank.BIG_JOKER),
    ];
    const result = determinePlay(jokerBomb);
    expect(result).not.toBeNull();
    expect(result!.type).toBe(PlayType.JOKER_BOMB);
    expect(result!.value).toBe(999);
  });

  it('returns null for two different ranks (not jokers)', () => {
    const invalid = [
      createCard(Suit.SPADE, Rank.ACE),
      createCard(Suit.HEART, Rank.KING),
    ];
    expect(determinePlay(invalid)).toBeNull();
  });

  it('identifies BOMB (3 of a kind)', () => {
    const bomb = [
      createCard(Suit.SPADE, Rank.TWO),
      createCard(Suit.HEART, Rank.TWO),
      createCard(Suit.CLUB, Rank.TWO),
    ];
    const result = determinePlay(bomb);
    expect(result).not.toBeNull();
    expect(result!.type).toBe(PlayType.BOMB);
    expect(result!.value).toBe(15);
  });

  it('identifies BIG_BOMB (4 of a kind)', () => {
    const bigBomb = [
      createCard(Suit.SPADE, Rank.SEVEN),
      createCard(Suit.HEART, Rank.SEVEN),
      createCard(Suit.CLUB, Rank.SEVEN),
      createCard(Suit.DIAMOND, Rank.SEVEN),
    ];
    const result = determinePlay(bigBomb);
    expect(result).not.toBeNull();
    expect(result!.type).toBe(PlayType.BIG_BOMB);
  });

  it('returns null for 3 cards not all same rank', () => {
    const invalid = [
      createCard(Suit.SPADE, Rank.ACE),
      createCard(Suit.HEART, Rank.ACE),
      createCard(Suit.SPADE, Rank.KING),
    ];
    expect(determinePlay(invalid)).toBeNull();
  });

  it('returns null for 5+ cards', () => {
    const tooMany = [
      createCard(Suit.SPADE, Rank.FIVE),
      createCard(Suit.HEART, Rank.FIVE),
      createCard(Suit.CLUB, Rank.FIVE),
      createCard(Suit.DIAMOND, Rank.FIVE),
      createCard(Suit.DIAMOND, Rank.SIX),
    ];
    expect(determinePlay(tooMany)).toBeNull();
  });

  it('jokers cannot form pairs with regular cards', () => {
    const invalid = [
      createCard(Suit.JOKER, Rank.SMALL_JOKER),
      createCard(Suit.SPADE, Rank.ACE),
    ];
    expect(determinePlay(invalid)).toBeNull();
  });
});

describe('canBeat', () => {
  it('any play beats null board (new trick)', () => {
    const play = determinePlay([createCard(Suit.SPADE, Rank.FIVE)])!;
    expect(canBeat(play, null)).toBe(true);
  });

  it('higher single beats lower single', () => {
    const low = determinePlay([createCard(Suit.SPADE, Rank.FIVE)])!;
    const high = determinePlay([createCard(Suit.SPADE, Rank.ACE)])!;
    expect(canBeat(high, low)).toBe(true);
    expect(canBeat(low, high)).toBe(false);
  });

  it('pair cannot beat single (same tier different shape)', () => {
    const single = determinePlay([createCard(Suit.SPADE, Rank.ACE)])!;
    const pair = determinePlay([
      createCard(Suit.SPADE, Rank.FIVE),
      createCard(Suit.HEART, Rank.FIVE),
    ])!;
    expect(canBeat(pair, single)).toBe(false);
    expect(canBeat(single, pair)).toBe(false);
  });

  it('bomb beats single', () => {
    const single = determinePlay([createCard(Suit.SPADE, Rank.ACE)])!;
    const bomb = determinePlay([
      createCard(Suit.SPADE, Rank.FIVE),
      createCard(Suit.HEART, Rank.FIVE),
      createCard(Suit.CLUB, Rank.FIVE),
    ])!;
    expect(canBeat(bomb, single)).toBe(true);
  });

  it('bomb beats pair', () => {
    const pair = determinePlay([
      createCard(Suit.SPADE, Rank.ACE),
      createCard(Suit.HEART, Rank.ACE),
    ])!;
    const bomb = determinePlay([
      createCard(Suit.SPADE, Rank.FIVE),
      createCard(Suit.HEART, Rank.FIVE),
      createCard(Suit.CLUB, Rank.FIVE),
    ])!;
    expect(canBeat(bomb, pair)).toBe(true);
  });

  it('big bomb beats bomb', () => {
    const bomb = determinePlay([
      createCard(Suit.SPADE, Rank.ACE),
      createCard(Suit.HEART, Rank.ACE),
      createCard(Suit.CLUB, Rank.ACE),
    ])!;
    const bigBomb = determinePlay([
      createCard(Suit.SPADE, Rank.FIVE),
      createCard(Suit.HEART, Rank.FIVE),
      createCard(Suit.CLUB, Rank.FIVE),
      createCard(Suit.DIAMOND, Rank.FIVE),
    ])!;
    expect(canBeat(bigBomb, bomb)).toBe(true);
    expect(canBeat(bomb, bigBomb)).toBe(false);
  });

  it('joker bomb beats everything', () => {
    const bigBomb = determinePlay([
      createCard(Suit.SPADE, Rank.ACE),
      createCard(Suit.HEART, Rank.ACE),
      createCard(Suit.CLUB, Rank.ACE),
      createCard(Suit.DIAMOND, Rank.ACE),
    ])!;
    const jokerBomb = determinePlay([
      createCard(Suit.JOKER, Rank.SMALL_JOKER),
      createCard(Suit.JOKER, Rank.BIG_JOKER),
    ])!;
    expect(canBeat(jokerBomb, bigBomb)).toBe(true);
    expect(canBeat(bigBomb, jokerBomb)).toBe(false);
  });

  it('higher bomb beats lower bomb', () => {
    const lowBomb = determinePlay([
      createCard(Suit.SPADE, Rank.FIVE),
      createCard(Suit.HEART, Rank.FIVE),
      createCard(Suit.CLUB, Rank.FIVE),
    ])!;
    const highBomb = determinePlay([
      createCard(Suit.SPADE, Rank.ACE),
      createCard(Suit.HEART, Rank.ACE),
      createCard(Suit.CLUB, Rank.ACE),
    ])!;
    expect(canBeat(highBomb, lowBomb)).toBe(true);
    expect(canBeat(lowBomb, highBomb)).toBe(false);
  });

  it('revealed red three single can beat regular four', () => {
    const redThree = createCard(Suit.HEART, Rank.THREE);
    redThree.isRevealed = true;
    const four = createCard(Suit.SPADE, Rank.FOUR);

    const redThreePlay = determinePlay([redThree])!;
    const fourPlay = determinePlay([four])!;

    expect(redThreePlay.value).toBe(17.5);
    expect(fourPlay.value).toBe(17);
    expect(canBeat(redThreePlay, fourPlay)).toBe(true);
    expect(canBeat(fourPlay, redThreePlay)).toBe(false);
  });
});

describe('isValidOpeningPlay', () => {
  it('validates play with 红桃5', () => {
    const hand = [
      createCard(Suit.HEART, Rank.FIVE),
      createCard(Suit.SPADE, Rank.ACE),
    ];
    const selected = [createCard(Suit.HEART, Rank.FIVE)];
    expect(isValidOpeningPlay(hand, selected)).toBe(true);
  });

  it('rejects opening without 红桃5', () => {
    const hand = [createCard(Suit.SPADE, Rank.FIVE)];
    const selected = [createCard(Suit.SPADE, Rank.FIVE)];
    expect(isValidOpeningPlay(hand, selected)).toBe(false);
  });

  it('rejects opening with non-5 cards', () => {
    const hand = [
      createCard(Suit.HEART, Rank.FIVE),
      createCard(Suit.SPADE, Rank.ACE),
    ];
    const selected = [
      createCard(Suit.HEART, Rank.FIVE),
      createCard(Suit.SPADE, Rank.ACE),
    ];
    expect(isValidOpeningPlay(hand, selected)).toBe(false);
  });

  it('allows opening with multiple 5s', () => {
    const hand = [
      createCard(Suit.HEART, Rank.FIVE),
      createCard(Suit.SPADE, Rank.FIVE),
      createCard(Suit.CLUB, Rank.FIVE),
    ];
    const selected = [
      createCard(Suit.HEART, Rank.FIVE),
      createCard(Suit.SPADE, Rank.FIVE),
    ];
    expect(isValidOpeningPlay(hand, selected)).toBe(true);
  });
});

describe('findHighestCard', () => {
  it('returns null for empty hand', () => {
    expect(findHighestCard([])).toBeNull();
  });

  it('returns highest power card', () => {
    const hand = [
      createCard(Suit.SPADE, Rank.FIVE),
      createCard(Suit.HEART, Rank.ACE),
      createCard(Suit.CLUB, Rank.TWO),
    ];
    const highest = findHighestCard(hand);
    expect(highest).not.toBeNull();
    expect(highest!.rank).toBe(Rank.TWO);
  });
});

describe('getRevealEligibility', () => {
  it('3-player: only 红桃3 can reveal', () => {
    const hand = [
      createCard(Suit.HEART, Rank.THREE),
      createCard(Suit.DIAMOND, Rank.THREE),
    ];
    const eligibility = getRevealEligibility(hand, 3);
    expect(eligibility.mustReveal).toHaveLength(0);
    expect(eligibility.canReveal).toHaveLength(1);
    expect(eligibility.canReveal[0].suit).toBe(Suit.HEART);
  });

  it('4-player: both 红桃3 and 方片3 can reveal', () => {
    const hand = [
      createCard(Suit.HEART, Rank.THREE),
      createCard(Suit.DIAMOND, Rank.THREE),
    ];
    const eligibility = getRevealEligibility(hand, 4);
    expect(eligibility.mustReveal).toHaveLength(0);
    expect(eligibility.canReveal).toHaveLength(2);
  });

  it('5-player: 方片3 must reveal, 红桃3 can reveal', () => {
    const hand = [
      createCard(Suit.HEART, Rank.THREE),
      createCard(Suit.DIAMOND, Rank.THREE),
    ];
    const eligibility = getRevealEligibility(hand, 5);
    expect(eligibility.mustReveal).toHaveLength(1);
    expect(eligibility.mustReveal[0].suit).toBe(Suit.DIAMOND);
    expect(eligibility.canReveal).toHaveLength(1);
    expect(eligibility.canReveal[0].suit).toBe(Suit.HEART);
  });

  it('no eligibility when no red threes', () => {
    const hand = [createCard(Suit.SPADE, Rank.ACE)];
    expect(getRevealEligibility(hand, 4).canReveal).toHaveLength(0);
    expect(getRevealEligibility(hand, 4).mustReveal).toHaveLength(0);
  });
});

describe('applyReveal', () => {
  it('marks cards as revealed', () => {
    const hand = [
      createCard(Suit.HEART, Rank.THREE),
      createCard(Suit.DIAMOND, Rank.THREE),
      createCard(Suit.SPADE, Rank.ACE),
    ];
    applyReveal(hand, ['H_16']);
    expect(hand[0].isRevealed).toBe(true);
    expect(hand[1].isRevealed).toBe(false);
  });
});

describe('sortHand', () => {
  it('sorts by power descending', () => {
    const hand = [
      createCard(Suit.SPADE, Rank.FIVE),
      createCard(Suit.HEART, Rank.ACE),
      createCard(Suit.CLUB, Rank.TWO),
    ];
    const sorted = sortHand(hand);
    expect(sorted[0].rank).toBe(Rank.TWO);
    expect(sorted[1].rank).toBe(Rank.ACE);
    expect(sorted[2].rank).toBe(Rank.FIVE);
  });
});

describe('createDeck', () => {
  it('creates 54 cards', () => {
    const deck = createDeck();
    expect(deck).toHaveLength(54);
  });

  it('contains 2 jokers', () => {
    const deck = createDeck();
    const jokers = deck.filter((c) => c.suit === Suit.JOKER);
    expect(jokers).toHaveLength(2);
  });

  it('contains all 4 suits x 13 ranks', () => {
    const deck = createDeck();
    const regular = deck.filter((c) => c.suit !== Suit.JOKER);
    expect(regular).toHaveLength(52);
  });
});
