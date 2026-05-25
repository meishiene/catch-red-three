import { Card, BoardState, PlayInfo, PlayType } from '../engine/types';
import { determinePlay, getSingleCardPower } from '../engine/card';

export enum AIDifficulty {
  EASY = 'EASY',
  NORMAL = 'NORMAL',
  HARD = 'HARD',
}

export function scorePlay(
  play: Card[],
  hand: Card[],
  boardState: BoardState | null,
  difficulty: AIDifficulty,
  isTeamLeader: boolean,
  teamCardCounts: number[]
): number {
  switch (difficulty) {
    case AIDifficulty.EASY:
      return scoreEasy(play, boardState);
    case AIDifficulty.NORMAL:
      return scoreNormal(play, hand);
    case AIDifficulty.HARD:
      return scoreHard(play, hand, boardState, isTeamLeader, teamCardCounts);
  }
}

function scoreEasy(play: Card[], boardState: BoardState | null): number {
  return Math.random() * 100;
}

function scoreNormal(play: Card[], hand: Card[]): number {
  let score = 0;
  const playInfo = determinePlay(play);
  if (!playInfo) return -1;

  // Prefer playing lower-value cards
  const avgPower = play.reduce((sum, c) => sum + getSingleCardPower(c), 0) / play.length;
  score += (20 - avgPower) * 2;

  // Bonus for playing bombs (keep them for later)
  if (playInfo.type === PlayType.BOMB) score -= 10;
  if (playInfo.type === PlayType.BIG_BOMB) score -= 15;

  // Prefer playing singles over pairs (more flexible)
  if (playInfo.type === PlayType.SINGLE) score += 5;

  // Prefer playing more cards to reduce hand size
  score += play.length * 2;

  return score;
}

function scoreHard(
  play: Card[],
  hand: Card[],
  boardState: BoardState | null,
  isTeamLeader: boolean,
  teamCardCounts: number[]
): number {
  let score = 0;
  const playInfo = determinePlay(play);
  if (!playInfo) return -1;

  const avgPower = play.reduce((sum, c) => sum + getSingleCardPower(c), 0) / play.length;
  const remainingAfterPlay = hand.length - play.length;

  // Prioritize getting rid of low cards
  score += (20 - avgPower) * 1.5;

  // Increase urgency when few cards remain
  if (remainingAfterPlay <= 3) score += 30;
  if (remainingAfterPlay === 0) score += 100;

  // Play more cards when possible
  score += play.length * 3;

  // Strategic bomb usage
  if (playInfo.type === PlayType.JOKER_BOMB) {
    score -= 50;
    if (remainingAfterPlay <= 3) score += 60;
  } else if (playInfo.type === PlayType.BOMB || playInfo.type === PlayType.BIG_BOMB) {
    // Use bombs when: close to finishing, or when teammates are behind
    if (remainingAfterPlay <= 3) {
      score += 40;
    }
    // Don't waste bombs early
    if (hand.length > 10) score -= 20;
  }

  // Consider team: if teammate is leading (few cards), try to help
  if (teamCardCounts.length > 0) {
    const minTeamCards = Math.min(...teamCardCounts);
    if (minTeamCards <= 3) {
      // Teammate close to winning, play aggressively
      score += 10;
    }
  }

  // If not leading and board has high cards, consider passing
  if (!isTeamLeader && boardState && playInfo.type === PlayType.SINGLE) {
    if (avgPower > 15 && hand.length > 5) {
      score -= 30; // Don't waste high cards early
    }
  }

  return score;
}

export function shouldPass(
  hand: Card[],
  boardState: BoardState | null,
  difficulty: AIDifficulty,
  isTrickLeader: boolean
): boolean {
  if (isTrickLeader && boardState === null) return false;

  switch (difficulty) {
    case AIDifficulty.EASY:
      return Math.random() < 0.5;
    case AIDifficulty.NORMAL:
      return false; // Will pass only when no legal plays
    case AIDifficulty.HARD:
      // Pass strategically: when hand is large and play would waste high cards
      if (hand.length > 8 && boardState) {
        return Math.random() < 0.2;
      }
      return false;
  }
}

export function shouldRevealIdentity(
  hand: Card[],
  canReveal: Card[],
  mustReveal: Card[],
  difficulty: AIDifficulty
): string[] {
  const toReveal: string[] = [];

  // Always reveal mandatory cards
  toReveal.push(...mustReveal.map((c) => c.id));

  switch (difficulty) {
    case AIDifficulty.EASY:
      // 30% chance to reveal optional cards
      for (const card of canReveal) {
        if (Math.random() < 0.3) toReveal.push(card.id);
      }
      break;
    case AIDifficulty.NORMAL:
    case AIDifficulty.HARD:
      // Always reveal optional cards for power boost
      toReveal.push(...canReveal.map((c) => c.id));
      break;
  }

  return toReveal;
}

export function chooseTributeReturnCard(
  hand: Card[],
  difficulty: AIDifficulty
): Card {
  switch (difficulty) {
    case AIDifficulty.EASY:
    case AIDifficulty.NORMAL:
      return hand[Math.floor(Math.random() * hand.length)];
    case AIDifficulty.HARD: {
      // Return the lowest power card
      return hand.reduce((min, c) =>
        getSingleCardPower(c) < getSingleCardPower(min) ? c : min
      );
    }
  }
}
