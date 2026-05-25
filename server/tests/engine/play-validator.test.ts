import { validatePlay, validatePass, getAllLegalPlays } from '../../src/engine/play-validator';
import { createCard, determinePlay } from '../../src/engine/card';
import { Suit, Rank, PlayType, BoardState } from '../../src/engine/types';

function makeBoard(cards: { suit: Suit; rank: Rank }[]): BoardState {
  const c = cards.map((c) => createCard(c.suit, c.rank));
  const play = determinePlay(c)!;
  return {
    cards: c,
    playType: play.type,
    playedByPlayerId: 'other',
    isNewTrick: false,
  };
}

describe('validatePlay', () => {
  it('validates a valid single play', () => {
    const hand = [createCard(Suit.SPADE, Rank.ACE), createCard(Suit.HEART, Rank.FIVE)];
    const result = validatePlay(
      [createCard(Suit.SPADE, Rank.ACE)],
      hand,
      null,
      false,
      true
    );
    expect(result.valid).toBe(true);
    expect(result.playInfo?.type).toBe(PlayType.SINGLE);
  });

  it('rejects cards not in hand', () => {
    const hand = [createCard(Suit.SPADE, Rank.ACE)];
    const result = validatePlay(
      [createCard(Suit.HEART, Rank.KING)],
      hand,
      null,
      false,
      true
    );
    expect(result.valid).toBe(false);
    expect(result.error).toContain('不在手中');
  });

  it('rejects invalid combinations', () => {
    const hand = [
      createCard(Suit.SPADE, Rank.ACE),
      createCard(Suit.HEART, Rank.KING),
    ];
    const result = validatePlay(hand, hand, null, false, true);
    expect(result.valid).toBe(false);
    expect(result.error).toContain('无效的牌型组合');
  });

  it('validates opening play with 红桃5', () => {
    const hand = [
      createCard(Suit.HEART, Rank.FIVE),
      createCard(Suit.SPADE, Rank.ACE),
    ];
    const selected = [createCard(Suit.HEART, Rank.FIVE)];
    const result = validatePlay(selected, hand, null, true, true);
    expect(result.valid).toBe(true);
  });

  it('rejects opening without 红桃5', () => {
    const hand = [createCard(Suit.SPADE, Rank.FIVE)];
    const selected = [createCard(Suit.SPADE, Rank.FIVE)];
    const result = validatePlay(selected, hand, null, true, true);
    expect(result.valid).toBe(false);
    expect(result.error).toContain('红桃5');
  });

  it('allows any play when leading a non-first trick', () => {
    const hand = [createCard(Suit.SPADE, Rank.ACE), createCard(Suit.HEART, Rank.FIVE)];
    const selected = [createCard(Suit.HEART, Rank.FIVE)];
    const result = validatePlay(selected, hand, null, false, true);
    expect(result.valid).toBe(true);
  });

  it('validates beating with higher card', () => {
    const board = makeBoard([{ suit: Suit.SPADE, rank: Rank.FIVE }]);
    const hand = [createCard(Suit.HEART, Rank.ACE)];
    const result = validatePlay(
      [createCard(Suit.HEART, Rank.ACE)],
      hand,
      board,
      false,
      false
    );
    expect(result.valid).toBe(true);
  });

  it('rejects lower card not beating board', () => {
    const board = makeBoard([{ suit: Suit.HEART, rank: Rank.ACE }]);
    const hand = [createCard(Suit.SPADE, Rank.FIVE)];
    const result = validatePlay(
      [createCard(Suit.SPADE, Rank.FIVE)],
      hand,
      board,
      false,
      false
    );
    expect(result.valid).toBe(false);
    expect(result.error).toContain('打不过');
  });

  it('allows bomb to beat single on board', () => {
    const board = makeBoard([{ suit: Suit.HEART, rank: Rank.ACE }]);
    const hand = [
      createCard(Suit.SPADE, Rank.TEN),
      createCard(Suit.HEART, Rank.TEN),
      createCard(Suit.CLUB, Rank.TEN),
    ];
    const selected = [
      createCard(Suit.SPADE, Rank.TEN),
      createCard(Suit.HEART, Rank.TEN),
      createCard(Suit.CLUB, Rank.TEN),
    ];
    const result = validatePlay(selected, hand, board, false, false);
    expect(result.valid).toBe(true);
  });

  it('rejects duplicate card selection', () => {
    const hand = [createCard(Suit.SPADE, Rank.ACE)];
    const result = validatePlay(
      [createCard(Suit.SPADE, Rank.ACE), createCard(Suit.SPADE, Rank.ACE)],
      hand,
      null,
      false,
      true
    );
    expect(result.valid).toBe(false);
    expect(result.error).toContain('重复');
  });
});

describe('validatePass', () => {
  it('rejects pass when trick leader (no board)', () => {
    const result = validatePass(true, null);
    expect(result.valid).toBe(false);
  });

  it('allows pass when there is a board', () => {
    const board = makeBoard([{ suit: Suit.SPADE, rank: Rank.FIVE }]);
    const result = validatePass(false, board);
    expect(result.valid).toBe(true);
  });
});

describe('getAllLegalPlays', () => {
  it('returns all singles when no board', () => {
    const hand = [
      createCard(Suit.SPADE, Rank.FIVE),
      createCard(Suit.HEART, Rank.ACE),
    ];
    const plays = getAllLegalPlays(hand, null);
    const singles = plays.filter((p) => p.length === 1);
    expect(singles.length).toBeGreaterThanOrEqual(2);
  });

  it('returns only plays that beat the board', () => {
    const board = makeBoard([{ suit: Suit.SPADE, rank: Rank.KING }]);
    const hand = [
      createCard(Suit.SPADE, Rank.FIVE),
      createCard(Suit.HEART, Rank.ACE),
    ];
    const plays = getAllLegalPlays(hand, board);
    for (const play of plays) {
      const info = determinePlay(play)!;
      const boardInfo = determinePlay(board.cards)!;
      expect(info.value).toBeGreaterThan(boardInfo.value);
    }
  });

  it('includes bombs as legal plays vs singles', () => {
    const board = makeBoard([{ suit: Suit.HEART, rank: Rank.ACE }]);
    const hand = [
      createCard(Suit.SPADE, Rank.FIVE),
      createCard(Suit.HEART, Rank.FIVE),
      createCard(Suit.CLUB, Rank.FIVE),
    ];
    const plays = getAllLegalPlays(hand, board);
    expect(plays.length).toBeGreaterThan(0);
    expect(plays.some((p) => p.length === 3)).toBe(true);
  });

  it('returns joker bomb as legal play', () => {
    const board = makeBoard([{ suit: Suit.HEART, rank: Rank.ACE }]);
    const hand = [
      createCard(Suit.JOKER, Rank.SMALL_JOKER),
      createCard(Suit.JOKER, Rank.BIG_JOKER),
    ];
    const plays = getAllLegalPlays(hand, board);
    expect(plays.some((p) => p.length === 2 &&
      p.every((c) => c.suit === Suit.JOKER)
    )).toBe(true);
  });
});
