import { Card, Team, Rank, Suit } from './types';

export function assignTeams(
  hands: Map<string, Card[]>
): Map<string, Team> {
  const teams = new Map<string, Team>();

  const redThreeHolders: string[] = [];
  for (const [playerId, hand] of hands) {
    const hasRedThree = hand.some(
      (c) =>
        (c.suit === Suit.HEART || c.suit === Suit.DIAMOND) &&
        c.rank === Rank.THREE
    );
    if (hasRedThree) redThreeHolders.push(playerId);
  }

  for (const [playerId] of hands) {
    teams.set(playerId, redThreeHolders.includes(playerId) ? 'red' : 'black');
  }

  return teams;
}

export function getRedThreeHolder(
  hands: Map<string, Card[]>,
  suit: Suit
): string | null {
  for (const [playerId, hand] of hands) {
    const has = hand.some(
      (c) => c.suit === suit && c.rank === Rank.THREE
    );
    if (has) return playerId;
  }
  return null;
}

export function getTeamMembers(
  teams: Map<string, Team>,
  team: Team
): string[] {
  const members: string[] = [];
  for (const [playerId, t] of teams) {
    if (t === team) members.push(playerId);
  }
  return members;
}
