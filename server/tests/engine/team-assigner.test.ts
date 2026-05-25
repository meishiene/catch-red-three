import { assignTeams, getRedThreeHolder, getTeamMembers } from '../../src/engine/team-assigner';
import { createCard } from '../../src/engine/card';
import { Suit, Rank } from '../../src/engine/types';

describe('assignTeams', () => {
  it('3 players: 红桃3 holder is red, others black', () => {
    const hands = new Map<string, import('../../src/engine/types').Card[]>();
    hands.set('p1', [createCard(Suit.HEART, Rank.THREE)]);
    hands.set('p2', [createCard(Suit.SPADE, Rank.ACE)]);
    hands.set('p3', [createCard(Suit.CLUB, Rank.KING)]);

    const teams = assignTeams(hands);
    expect(teams.get('p1')).toBe('red');
    expect(teams.get('p2')).toBe('black');
    expect(teams.get('p3')).toBe('black');
  });

  it('4 players: both red 3 holders are red', () => {
    const hands = new Map<string, import('../../src/engine/types').Card[]>();
    hands.set('p1', [createCard(Suit.HEART, Rank.THREE)]);
    hands.set('p2', [createCard(Suit.DIAMOND, Rank.THREE)]);
    hands.set('p3', [createCard(Suit.SPADE, Rank.ACE)]);
    hands.set('p4', [createCard(Suit.CLUB, Rank.KING)]);

    const teams = assignTeams(hands);
    expect(teams.get('p1')).toBe('red');
    expect(teams.get('p2')).toBe('red');
    expect(teams.get('p3')).toBe('black');
    expect(teams.get('p4')).toBe('black');
  });

  it('if one player holds both red 3s, they are red alone', () => {
    const hands = new Map<string, import('../../src/engine/types').Card[]>();
    hands.set('p1', [
      createCard(Suit.HEART, Rank.THREE),
      createCard(Suit.DIAMOND, Rank.THREE),
    ]);
    hands.set('p2', [createCard(Suit.SPADE, Rank.ACE)]);
    hands.set('p3', [createCard(Suit.CLUB, Rank.KING)]);

    const teams = assignTeams(hands);
    expect(teams.get('p1')).toBe('red');
    expect(teams.get('p2')).toBe('black');
    expect(teams.get('p3')).toBe('black');
  });

  it('5 players: red 3 holders are red', () => {
    const hands = new Map<string, import('../../src/engine/types').Card[]>();
    hands.set('p1', [createCard(Suit.HEART, Rank.THREE)]);
    hands.set('p2', [createCard(Suit.DIAMOND, Rank.THREE)]);
    hands.set('p3', [createCard(Suit.SPADE, Rank.ACE)]);
    hands.set('p4', [createCard(Suit.CLUB, Rank.KING)]);
    hands.set('p5', [createCard(Suit.SPADE, Rank.TWO)]);

    const teams = assignTeams(hands);
    expect(teams.get('p1')).toBe('red');
    expect(teams.get('p2')).toBe('red');
    expect(teams.get('p3')).toBe('black');
    expect(teams.get('p4')).toBe('black');
    expect(teams.get('p5')).toBe('black');
  });
});

describe('getTeamMembers', () => {
  it('returns correct members for each team', () => {
    const teams = new Map<string, 'red' | 'black'>();
    teams.set('p1', 'red');
    teams.set('p2', 'black');
    teams.set('p3', 'black');

    expect(getTeamMembers(teams, 'red')).toEqual(['p1']);
    expect(getTeamMembers(teams, 'black')).toEqual(['p2', 'p3']);
  });
});
