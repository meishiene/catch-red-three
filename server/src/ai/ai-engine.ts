import { Card, BoardState, Team } from '../engine/types';
import { getAllLegalPlays } from '../engine/play-validator';
import { sortHand } from '../engine/card';
import { AIDifficulty, scorePlay, shouldPass, shouldRevealIdentity, chooseTributeReturnCard } from './ai-scorer';

export interface AIDecision {
  action: 'play' | 'pass';
  cards?: Card[];
}

export function decideAI(
  hand: Card[],
  boardState: BoardState | null,
  difficulty: AIDifficulty,
  isTrickLeader: boolean,
  isFirstTrick: boolean,
  team: Team,
  teamCardCounts: number[]
): AIDecision {
  const legalPlays = getAllLegalPlays(hand, boardState);

  if (legalPlays.length === 0) {
    return { action: 'pass' };
  }

  if (shouldPass(hand, boardState, difficulty, isTrickLeader)) {
    return { action: 'pass' };
  }

  // Score and rank all legal plays
  const scored = legalPlays.map((cards) => ({
    cards,
    score: scorePlay(cards, hand, boardState, difficulty, isTrickLeader, teamCardCounts),
  }));

  scored.sort((a, b) => b.score - a.score);

  return { action: 'play', cards: scored[0].cards };
}

export function aiRevealDecision(
  hand: Card[],
  canReveal: Card[],
  mustReveal: Card[],
  difficulty: AIDifficulty
): string[] {
  return shouldRevealIdentity(hand, canReveal, mustReveal, difficulty);
}

export function aiTributeReturnCard(
  hand: Card[],
  difficulty: AIDifficulty
): Card {
  return chooseTributeReturnCard(hand, difficulty);
}

export function aiSelectOpeningPlay(
  hand: Card[],
  difficulty: AIDifficulty
): Card[] {
  // Find all 5s in hand
  const fives = hand.filter((c) => c.rank === 5);

  if (difficulty === AIDifficulty.EASY) {
    return [fives[0]];
  }

  // Normal and Hard: play subset of 5s strategically
  if (difficulty === AIDifficulty.NORMAL) {
    // Play as many 5s as make a valid play
    if (fives.length >= 4) return fives.slice(0, 4);
    if (fives.length === 3) return fives.slice(0, 3);
    if (fives.length >= 2) return fives.slice(0, 2);
    return [fives[0]];
  }

  // Hard: play minimally to keep options
  return [fives[0]];
}
