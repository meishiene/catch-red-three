import { Team, GameResult } from './types';

export function determineWinner(
  finishOrder: string[],
  teams: Map<string, Team>
): GameResult {
  const firstFinisherId = finishOrder[0];
  const lastFinisherId = finishOrder[finishOrder.length - 1];
  const firstTeam = teams.get(firstFinisherId)!;
  const lastTeam = teams.get(lastFinisherId)!;

  const finishOrderResult = finishOrder.map((playerId, index) => ({
    playerId,
    position: index + 1,
  }));

  const redTeam: { playerId: string; isCaught: boolean }[] = [];
  const blackTeam: { playerId: string; isCaught: boolean }[] = [];

  for (const [playerId, team] of teams) {
    const isCaught = playerId === lastFinisherId;
    if (team === 'red') {
      redTeam.push({ playerId, isCaught });
    } else {
      blackTeam.push({ playerId, isCaught });
    }
  }

  let winner: Team | 'draw';
  if (firstTeam !== lastTeam) {
    winner = firstTeam;
  } else {
    winner = 'draw';
  }

  return {
    winner,
    finishOrder: finishOrderResult,
    redTeam,
    blackTeam,
    firstFinisherId,
    caughtPlayerId: winner !== 'draw' ? lastFinisherId : null,
  };
}

export function isGameOver(
  unfinishedCount: number,
  totalPlayers: number
): boolean {
  return unfinishedCount <= 1;
}
