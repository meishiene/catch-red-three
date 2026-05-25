import { Card, GameResult, Team, Suit, Rank, TributePair } from './types';
import { findHighestCard, getSingleCardPower } from './card';
import { getTeamMembers } from './team-assigner';

export function determineTributePairs(
  gameResult: GameResult,
  teams: Map<string, Team>,
  hands: Map<string, Card[]>,
  maxPlayers: number
): TributePair[] {
  if (gameResult.winner === 'draw') return [];

  const loserTeam: Team = gameResult.winner === 'red' ? 'black' : 'red';
  const winners = getTeamMembers(teams, gameResult.winner);
  const losers = getTeamMembers(teams, loserTeam);

  const pairs: TributePair[] = [];

  if (maxPlayers === 3) {
    if (gameResult.winner === 'red') {
      // Red (1 player) wins: 2 black losers each give 1 to red
      for (const loserId of losers) {
        pairs.push({ fromPlayerId: loserId, toPlayerId: winners[0] });
      }
    } else {
      // Black wins: 1 red loser gives to first-finishing black player
      pairs.push({ fromPlayerId: losers[0], toPlayerId: gameResult.firstFinisherId });
    }
  } else if (maxPlayers === 4) {
    // 2 red vs 2 black: 1-to-1 pairing
    const shuffledWinners = [...winners].sort(() => Math.random() - 0.5);
    const shuffledLosers = [...losers].sort(() => Math.random() - 0.5);
    for (let i = 0; i < Math.min(winners.length, losers.length); i++) {
      pairs.push({ fromPlayerId: shuffledLosers[i], toPlayerId: shuffledWinners[i] });
    }
  } else if (maxPlayers === 5) {
    // 2 red vs 3 black
    const redThreeHolder = findRedThreeHolderInTeams(hands, teams, Suit.HEART);
    const diamondThreeHolder = findRedThreeHolderInTeams(hands, teams, Suit.DIAMOND);

    if (gameResult.winner === 'red') {
      // Red wins: 红桃3 receives 2, 方片3 receives 1
      const blackLosers = [...losers].sort(() => Math.random() - 0.5);
      if (redThreeHolder) {
        for (let i = 0; i < 2 && i < blackLosers.length; i++) {
          pairs.push({ fromPlayerId: blackLosers[i], toPlayerId: redThreeHolder });
        }
      }
      if (diamondThreeHolder && blackLosers.length > 2) {
        pairs.push({ fromPlayerId: blackLosers[2], toPlayerId: diamondThreeHolder });
      }
    } else {
      // Black wins: 红桃3 gives 2, 方片3 gives 1
      const blackWinners = [...winners].sort(() => Math.random() - 0.5);
      if (redThreeHolder) {
        for (let i = 0; i < 2 && i < blackWinners.length; i++) {
          pairs.push({ fromPlayerId: redThreeHolder, toPlayerId: blackWinners[i] });
        }
      }
      if (diamondThreeHolder && blackWinners.length > 2) {
        pairs.push({ fromPlayerId: diamondThreeHolder, toPlayerId: blackWinners[2] });
      }
    }
  }

  return pairs;
}

function findRedThreeHolderInTeams(
  hands: Map<string, Card[]>,
  teams: Map<string, Team>,
  suit: Suit
): string | null {
  for (const [playerId, team] of teams) {
    if (team !== 'red') continue;
    const hand = hands.get(playerId);
    if (!hand) continue;
    const has = hand.some((c) => c.suit === suit && c.rank === Rank.THREE);
    if (has) return playerId;
  }
  return null;
}

export function applyTributeGive(
  hands: Map<string, Card[]>,
  pair: TributePair
): Card | null {
  const loserHand = hands.get(pair.fromPlayerId);
  if (!loserHand || loserHand.length === 0) return null;

  const highestCard = findHighestCard(loserHand);
  if (!highestCard) return null;

  const index = loserHand.findIndex((c) => c.id === highestCard.id);
  if (index === -1) return null;

  loserHand.splice(index, 1);
  pair.cardFromLoser = highestCard;
  return highestCard;
}

export function applyTributeReceive(
  hands: Map<string, Card[]>,
  pair: TributePair,
  returnCard: Card
): boolean {
  const winnerHand = hands.get(pair.toPlayerId);
  if (!winnerHand) return false;

  const index = winnerHand.findIndex((c) => c.id === returnCard.id);
  if (index === -1) return false;

  winnerHand.splice(index, 1);
  pair.cardFromWinner = returnCard;

  // Give loser's tribute card to winner
  if (pair.cardFromLoser) {
    winnerHand.push(pair.cardFromLoser);
  }

  // Give winner's return card to loser
  const loserHand = hands.get(pair.fromPlayerId);
  if (loserHand) {
    loserHand.push(returnCard);
  }

  return true;
}

export function executeFullTribute(
  hands: Map<string, Card[]>,
  pairs: TributePair[],
  returnCardChoices: Map<string, Card> // pair index (as string) -> return card
): void {
  for (let i = 0; i < pairs.length; i++) {
    const pair = pairs[i];
    const returnCard = returnCardChoices.get(String(i));
    if (!returnCard) continue;

    applyTributeGive(hands, pair);
    applyTributeReceive(hands, pair, returnCard);
  }
}
