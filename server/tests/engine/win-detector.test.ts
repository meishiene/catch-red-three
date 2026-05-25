import { determineWinner, isGameOver } from '../../src/engine/win-detector';

function makeTeams(map: Record<string, 'red' | 'black'>): Map<string, 'red' | 'black'> {
  const teams = new Map<string, 'red' | 'black'>();
  for (const [playerId, team] of Object.entries(map)) {
    teams.set(playerId, team);
  }
  return teams;
}

describe('determineWinner', () => {
  it('red wins: red first, black last', () => {
    const finishOrder = ['p1', 'p2', 'p3'];
    const teams = makeTeams({ p1: 'red', p2: 'black', p3: 'black' });

    const result = determineWinner(finishOrder, teams);
    expect(result.winner).toBe('red');
    expect(result.firstFinisherId).toBe('p1');
    expect(result.caughtPlayerId).toBe('p3');
  });

  it('black wins: black first, red last', () => {
    const finishOrder = ['p2', 'p3', 'p1'];
    const teams = makeTeams({ p1: 'red', p2: 'black', p3: 'black' });

    const result = determineWinner(finishOrder, teams);
    expect(result.winner).toBe('black');
    expect(result.firstFinisherId).toBe('p2');
    expect(result.caughtPlayerId).toBe('p1');
  });

  it('draw: red first AND red last', () => {
    const finishOrder = ['p1', 'p2', 'p3'];
    // p1 is red, p2 is red? No, in 3-player there's only 1 red.
    // Let me create a 4-player scenario: 2 red, 2 black
    const finishOrder4 = ['p1', 'p3', 'p4', 'p2'];
    const teams4 = makeTeams({ p1: 'red', p2: 'red', p3: 'black', p4: 'black' });
    // Red first (p1), Red last (p2) -> draw
    const result4 = determineWinner(finishOrder4, teams4);
    expect(result4.winner).toBe('draw');
  });

  it('draw: black first AND black last', () => {
    const finishOrder = ['p3', 'p1', 'p2', 'p4'];
    const teams = makeTeams({ p1: 'red', p2: 'red', p3: 'black', p4: 'black' });
    const result = determineWinner(finishOrder, teams);
    expect(result.winner).toBe('draw');
  });

  it('red wins in 4-player: red first, black last', () => {
    const finishOrder = ['p1', 'p3', 'p4', 'p2'];
    const teams = makeTeams({ p1: 'red', p2: 'red', p3: 'black', p4: 'black' });
    // Wait - p2 (red) is last here. Let me redo with red first, black last:
    const finishOrder2 = ['p1', 'p2', 'p3', 'p4'];
    const result = determineWinner(finishOrder2, teams);
    expect(result.winner).toBe('red');
    expect(result.firstFinisherId).toBe('p1');
    expect(result.caughtPlayerId).toBe('p4');
  });

  it('tracks caught players correctly', () => {
    const finishOrder = ['p1', 'p2', 'p3'];
    const teams = makeTeams({ p1: 'red', p2: 'black', p3: 'black' });
    const result = determineWinner(finishOrder, teams);

    const redCaught = result.redTeam.find((t) => t.playerId === 'p1');
    expect(redCaught?.isCaught).toBe(false);

    const blackCaught = result.blackTeam.find((t) => t.playerId === 'p3');
    expect(blackCaught?.isCaught).toBe(true);
  });

  it('correct finish order positions', () => {
    const finishOrder = ['p1', 'p2', 'p3'];
    const teams = makeTeams({ p1: 'red', p2: 'black', p3: 'black' });
    const result = determineWinner(finishOrder, teams);
    expect(result.finishOrder).toEqual([
      { playerId: 'p1', position: 1 },
      { playerId: 'p2', position: 2 },
      { playerId: 'p3', position: 3 },
    ]);
  });
});

describe('isGameOver', () => {
  it('returns true when 1 player remains', () => {
    expect(isGameOver(1, 3)).toBe(true);
  });

  it('returns true when 0 players remain', () => {
    expect(isGameOver(0, 3)).toBe(true);
  });

  it('returns false when multiple players remain', () => {
    expect(isGameOver(2, 3)).toBe(false);
    expect(isGameOver(3, 4)).toBe(false);
  });
});
