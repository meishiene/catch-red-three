import {
  determineTributePairs,
  applyTributeGive,
  applyTributeReceive,
} from '../../src/engine/tribute';
import { createCard } from '../../src/engine/card';
import { Suit, Rank, GameResult, Team } from '../../src/engine/types';

function makeResult(winner: Team | 'draw', firstFinisherId: string): GameResult {
  return {
    winner,
    finishOrder: [{ playerId: firstFinisherId, position: 1 }],
    redTeam: [],
    blackTeam: [],
    firstFinisherId,
    caughtPlayerId: winner !== 'draw' ? 'other' : null,
  };
}

function makeTeams(map: Record<string, Team>): Map<string, Team> {
  const teams = new Map<string, Team>();
  for (const [playerId, team] of Object.entries(map)) {
    teams.set(playerId, team);
  }
  return teams;
}

describe('determineTributePairs', () => {
  it('returns empty for draw', () => {
    const result = makeResult('draw', 'p1');
    const teams = makeTeams({ p1: 'red', p2: 'black', p3: 'black' });
    const hands = new Map();
    const pairs = determineTributePairs(result, teams, hands, 3);
    expect(pairs).toHaveLength(0);
  });

  it('3-player red win: 2 black each give to red', () => {
    const result = makeResult('red', 'p1');
    const teams = makeTeams({ p1: 'red', p2: 'black', p3: 'black' });
    const hands = new Map();
    const pairs = determineTributePairs(result, teams, hands, 3);
    expect(pairs).toHaveLength(2);
    expect(pairs.every((p) => p.toPlayerId === 'p1')).toBe(true);
    expect(pairs.map((p) => p.fromPlayerId).sort()).toEqual(['p2', 'p3']);
  });

  it('3-player black win: 1 red gives to first finisher', () => {
    const result = makeResult('black', 'p2');
    const teams = makeTeams({ p1: 'red', p2: 'black', p3: 'black' });
    const hands = new Map();
    const pairs = determineTributePairs(result, teams, hands, 3);
    expect(pairs).toHaveLength(1);
    expect(pairs[0].fromPlayerId).toBe('p1');
    expect(pairs[0].toPlayerId).toBe('p2');
  });

  it('5-player: 红桃3 holder handles 2 pairs', () => {
    const hands = new Map<string, import('../../src/engine/types').Card[]>();
    hands.set('p1', [createCard(Suit.HEART, Rank.THREE)]);
    hands.set('p2', [createCard(Suit.DIAMOND, Rank.THREE)]);
    hands.set('p3', [createCard(Suit.SPADE, Rank.ACE)]);
    hands.set('p4', [createCard(Suit.CLUB, Rank.KING)]);
    hands.set('p5', [createCard(Suit.SPADE, Rank.TWO)]);

    const result = {
      ...makeResult('red', 'p1'),
      finishOrder: [
        { playerId: 'p1', position: 1 },
        { playerId: 'p2', position: 2 },
        { playerId: 'p3', position: 3 },
        { playerId: 'p4', position: 4 },
        { playerId: 'p5', position: 5 },
      ],
      redTeam: [
        { playerId: 'p1', isCaught: false },
        { playerId: 'p2', isCaught: false },
      ],
      blackTeam: [
        { playerId: 'p3', isCaught: false },
        { playerId: 'p4', isCaught: false },
        { playerId: 'p5', isCaught: true },
      ],
      caughtPlayerId: 'p5',
    };

    const teams = makeTeams({
      p1: 'red', p2: 'red', p3: 'black', p4: 'black', p5: 'black',
    });

    const pairs = determineTributePairs(result, teams, hands, 5);

    // 红桃3 (p1) should receive from 2 black players
    const p1Pairs = pairs.filter((p) => p.toPlayerId === 'p1');
    expect(p1Pairs).toHaveLength(2);

    // 方片3 (p2) should receive from 1 black player
    const p2Pairs = pairs.filter((p) => p.toPlayerId === 'p2');
    expect(p2Pairs).toHaveLength(1);

    // Total: 3 pairs (3 black losers)
    expect(pairs).toHaveLength(3);
  });
});

describe('applyTributeGive', () => {
  it('removes highest card from loser hand', () => {
    const hands = new Map<string, import('../../src/engine/types').Card[]>();
    hands.set('loser', [
      createCard(Suit.SPADE, Rank.FIVE),
      createCard(Suit.HEART, Rank.ACE),
      createCard(Suit.CLUB, Rank.TWO),
    ]);
    hands.set('winner', [createCard(Suit.DIAMOND, Rank.THREE)]);

    const card = applyTributeGive(hands, { fromPlayerId: 'loser', toPlayerId: 'winner' });
    expect(card).not.toBeNull();
    expect(card!.rank).toBe(Rank.TWO); // Highest power

    const loserHand = hands.get('loser')!;
    expect(loserHand).toHaveLength(2);
    expect(loserHand.find((c) => c.rank === Rank.TWO)).toBeUndefined();
  });

  it('returns null for empty hand', () => {
    const hands = new Map<string, import('../../src/engine/types').Card[]>();
    hands.set('loser', []);
    hands.set('winner', []);

    const card = applyTributeGive(hands, { fromPlayerId: 'loser', toPlayerId: 'winner' });
    expect(card).toBeNull();
  });
});

describe('applyTributeReceive', () => {
  it('exchanges cards between winner and loser', () => {
    const hands = new Map<string, import('../../src/engine/types').Card[]>();
    const loserHand = [createCard(Suit.SPADE, Rank.FIVE)];
    const winnerHand = [createCard(Suit.HEART, Rank.ACE)];

    hands.set('loser', loserHand);
    hands.set('winner', winnerHand);

    const pair = {
      fromPlayerId: 'loser',
      toPlayerId: 'winner',
      cardFromLoser: createCard(Suit.CLUB, Rank.TWO), // highest card from loser
    };

    const returnCard = createCard(Suit.HEART, Rank.ACE); // winner gives this back

    const success = applyTributeReceive(hands, pair, returnCard);
    expect(success).toBe(true);

    // Winner should now have the tribute card
    expect(hands.get('winner')!.some((c) => c.id === pair.cardFromLoser!.id)).toBe(true);
    // Winner should no longer have the return card
    expect(hands.get('winner')!.some((c) => c.id === returnCard.id)).toBe(false);
    // Loser should have the return card
    expect(hands.get('loser')!.some((c) => c.id === returnCard.id)).toBe(true);
  });
});
