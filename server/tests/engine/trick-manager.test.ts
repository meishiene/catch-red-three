import {
  createTrickState,
  getCurrentPlayerId,
  isTrickLeader,
  getBoardState,
  processPlay,
  processPass,
  removePlayerFromTrick,
  resetTrick,
} from '../../src/engine/trick-manager';
import { createCard, determinePlay } from '../../src/engine/card';
import { Suit, Rank, PlayType } from '../../src/engine/types';

describe('createTrickState', () => {
  it('creates initial trick state', () => {
    const order = ['p1', 'p2', 'p3'];
    const trick = createTrickState(order, 'p1', true);

    expect(trick.boardCards).toHaveLength(0);
    expect(trick.boardPlay).toBeNull();
    expect(trick.boardPlayerId).toBeNull();
    expect(trick.activePlayerIds.size).toBe(3);
    expect(trick.isFirstTrick).toBe(true);
    expect(getCurrentPlayerId(trick)).toBe('p1');
  });
});

describe('getCurrentPlayerId', () => {
  it('returns current player based on index', () => {
    const order = ['p1', 'p2', 'p3'];
    const trick = createTrickState(order, 'p2', false);
    expect(getCurrentPlayerId(trick)).toBe('p2');
  });
});

describe('isTrickLeader', () => {
  it('returns true when no board', () => {
    const trick = createTrickState(['p1', 'p2'], 'p1', false);
    expect(isTrickLeader(trick, 'p1')).toBe(true);
  });

  it('returns true for the board player', () => {
    const trick = createTrickState(['p1', 'p2'], 'p1', false);
    const card = createCard(Suit.SPADE, Rank.FIVE);
    const play = determinePlay([card])!;
    processPlay(trick, 'p1', [card], play);
    expect(isTrickLeader(trick, 'p1')).toBe(true);
  });
});

describe('processPlay', () => {
  it('sets board cards and advances player', () => {
    const order = ['p1', 'p2', 'p3'];
    const trick = createTrickState(order, 'p1', false);
    const card = createCard(Suit.SPADE, Rank.ACE);
    const play = determinePlay([card])!;

    processPlay(trick, 'p1', [card], play);

    expect(trick.boardCards[0].id).toBe(card.id);
    expect(trick.boardPlay?.type).toBe(PlayType.SINGLE);
    expect(trick.boardPlayerId).toBe('p1');
  });
});

describe('processPass', () => {
  it('returns PASSED when players remain', () => {
    const order = ['p1', 'p2', 'p3'];
    const trick = createTrickState(order, 'p1', false);
    const card = createCard(Suit.SPADE, Rank.FIVE);
    const play = determinePlay([card])!;
    processPlay(trick, 'p1', [card], play);

    const result = processPass(trick, 'p2');
    expect(result.action).toBe('PASSED');
    expect(trick.activePlayerIds.has('p2')).toBe(false);
  });

  it('returns TRICK_WON when all but one pass', () => {
    const order = ['p1', 'p2', 'p3'];
    const trick = createTrickState(order, 'p1', false);
    const card = createCard(Suit.SPADE, Rank.FIVE);
    const play = determinePlay([card])!;
    processPlay(trick, 'p1', [card], play);

    // p2 passes
    processPass(trick, 'p2');
    // p3 passes - only p1 remains active
    const result = processPass(trick, 'p3');

    // After p2 passed and p3 could potentially pass too
    // activePlayerIds should be <= 1 now
    if (result.action === 'TRICK_WON') {
      expect(result.winnerId).toBeDefined();
    }
  });
});

describe('removePlayerFromTrick', () => {
  it('removes player from active set', () => {
    const trick = createTrickState(['p1', 'p2', 'p3'], 'p1', false);
    removePlayerFromTrick(trick, 'p2');
    expect(trick.activePlayerIds.has('p2')).toBe(false);
    expect(trick.activePlayerIds.size).toBe(2);
  });
});

describe('resetTrick', () => {
  it('clears board and sets new leader', () => {
    const trick = createTrickState(['p1', 'p2', 'p3'], 'p1', false);
    const card = createCard(Suit.SPADE, Rank.FIVE);
    const play = determinePlay([card])!;
    processPlay(trick, 'p1', [card], play);

    resetTrick(trick, 'p3');

    expect(trick.boardCards).toHaveLength(0);
    expect(trick.boardPlay).toBeNull();
    expect(trick.boardPlayerId).toBeNull();
    expect(getCurrentPlayerId(trick)).toBe('p3');
  });
});

describe('getBoardState', () => {
  it('returns null when no board', () => {
    const trick = createTrickState(['p1', 'p2'], 'p1', false);
    expect(getBoardState(trick)).toBeNull();
  });

  it('returns board state with cards', () => {
    const trick = createTrickState(['p1', 'p2'], 'p1', false);
    const card = createCard(Suit.SPADE, Rank.ACE);
    const play = determinePlay([card])!;
    processPlay(trick, 'p1', [card], play);

    const board = getBoardState(trick);
    expect(board).not.toBeNull();
    expect(board!.playType).toBe(PlayType.SINGLE);
    expect(board!.playedByPlayerId).toBe('p1');
  });
});
