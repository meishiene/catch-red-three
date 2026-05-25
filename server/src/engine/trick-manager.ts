import { Card, TrickState, PlayInfo, BoardState } from './types';
import { determinePlay } from './card';

export function createTrickState(
  playerOrder: string[],
  leaderPlayerId: string,
  isFirstTrick: boolean
): TrickState {
  return {
    boardCards: [],
    boardPlay: null,
    boardPlayerId: null,
    activePlayerIds: new Set(playerOrder),
    playerOrder,
    currentPlayerIndex: playerOrder.indexOf(leaderPlayerId),
    isFirstTrick,
  };
}

export function getCurrentPlayerId(trick: TrickState): string {
  return trick.playerOrder[trick.currentPlayerIndex];
}

export function isTrickLeader(trick: TrickState, playerId: string): boolean {
  return trick.boardPlayerId === null || trick.boardPlayerId === playerId;
}

export function getBoardState(trick: TrickState): BoardState | null {
  if (trick.boardCards.length === 0 || !trick.boardPlay || !trick.boardPlayerId) {
    return null;
  }
  return {
    cards: trick.boardCards,
    playType: trick.boardPlay.type,
    playedByPlayerId: trick.boardPlayerId,
    isNewTrick: false,
  };
}

export function processPlay(
  trick: TrickState,
  playerId: string,
  cards: Card[],
  playInfo: PlayInfo
): void {
  trick.boardCards = cards;
  trick.boardPlay = playInfo;
  trick.boardPlayerId = playerId;
  advanceToNextActivePlayer(trick);
}

export function processPass(
  trick: TrickState,
  playerId: string
): { action: 'PASSED' | 'TRICK_WON'; winnerId?: string } {
  trick.activePlayerIds.delete(playerId);
  advanceToNextActivePlayer(trick);

  if (trick.activePlayerIds.size <= 1) {
    const winnerId = trick.boardPlayerId || [...trick.activePlayerIds][0];
    return { action: 'TRICK_WON', winnerId };
  }

  return { action: 'PASSED' };
}

export function removePlayerFromTrick(
  trick: TrickState,
  playerId: string
): void {
  trick.activePlayerIds.delete(playerId);
}

export function resetTrick(trick: TrickState, newLeaderId: string): void {
  trick.boardCards = [];
  trick.boardPlay = null;
  trick.boardPlayerId = null;
  trick.currentPlayerIndex = trick.playerOrder.indexOf(newLeaderId);
}

function advanceToNextActivePlayer(trick: TrickState): void {
  const startIndex = trick.currentPlayerIndex;
  do {
    trick.currentPlayerIndex =
      (trick.currentPlayerIndex + 1) % trick.playerOrder.length;
    if (trick.currentPlayerIndex === startIndex) break;
  } while (!trick.activePlayerIds.has(getCurrentPlayerId(trick)));
}

export function isGameOverAfterPlay(
  activePlayerIds: Set<string>,
  totalPlayers: number
): boolean {
  return activePlayerIds.size <= 1;
}
