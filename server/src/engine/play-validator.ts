import { Card, BoardState, PlayInfo } from './types';
import { determinePlay, canBeat, isValidOpeningPlay } from './card';

export interface PlayValidationResult {
  valid: boolean;
  error?: string;
  playInfo?: PlayInfo;
}

export function validatePlay(
  selectedCards: Card[],
  playerHand: Card[],
  boardState: BoardState | null,
  isFirstTrick: boolean,
  isTrickLeader: boolean
): PlayValidationResult {
  const handIds = new Set(playerHand.map((c) => c.id));
  for (const card of selectedCards) {
    if (!handIds.has(card.id)) {
      return { valid: false, error: '选中的牌不在手中' };
    }
  }

  const selectedIds = new Set(selectedCards.map((c) => c.id));
  if (selectedIds.size !== selectedCards.length) {
    return { valid: false, error: '不能重复选择同一张牌' };
  }

  const playInfo = determinePlay(selectedCards);
  if (!playInfo) {
    return { valid: false, error: '无效的牌型组合' };
  }

  if (isFirstTrick && isTrickLeader) {
    if (!isValidOpeningPlay(playerHand, selectedCards)) {
      return { valid: false, error: '第一手必须包含红桃5且全部为5' };
    }
    return { valid: true, playInfo };
  }

  if (boardState === null || isTrickLeader) {
    return { valid: true, playInfo };
  }

  const boardPlay: PlayInfo = {
    type: boardState.playType,
    value: getBoardPlayValue(boardState),
  };

  if (!canBeat(playInfo, boardPlay)) {
    return { valid: false, error: '打不过当前桌面的牌' };
  }

  return { valid: true, playInfo };
}

function getBoardPlayValue(boardState: BoardState): number {
  if (boardState.cards.length === 0) return 0;
  const play = determinePlay(boardState.cards);
  return play ? play.value : 0;
}

export function validatePass(
  isTrickLeader: boolean,
  boardState: BoardState | null
): { valid: boolean; error?: string } {
  if (isTrickLeader && boardState === null) {
    return { valid: false, error: '新一轮必须出牌，不能过' };
  }
  if (boardState === null) {
    return { valid: false, error: '当前没有牌需要压，不能过' };
  }
  return { valid: true };
}

export function getAllLegalPlays(
  hand: Card[],
  boardState: BoardState | null
): Card[][] {
  const legalPlays: Card[][] = [];

  if (boardState === null) {
    return getAllPossiblePlays(hand);
  }

  const boardPlay = determinePlay(boardState.cards);
  if (!boardPlay) return [];

  const allPlays = getAllPossiblePlays(hand);
  for (const play of allPlays) {
    const playInfo = determinePlay(play);
    if (playInfo && canBeat(playInfo, boardPlay)) {
      legalPlays.push(play);
    }
  }

  return legalPlays;
}

function getAllPossiblePlays(hand: Card[]): Card[][] {
  const plays: Card[][] = [];
  const n = hand.length;

  for (let i = 0; i < n; i++) {
    plays.push([hand[i]]);
  }

  for (let i = 0; i < n; i++) {
    for (let j = i + 1; j < n; j++) {
      if (hand[i].rank === hand[j].rank) {
        plays.push([hand[i], hand[j]]);
      }
    }
  }

  const jokers = hand.filter((c) => c.id.includes('JOKER'));
  if (jokers.length >= 2) {
    const small = jokers.find((c) => c.id.includes('18'));
    const big = jokers.find((c) => c.id.includes('19'));
    if (small && big) {
      plays.push([small, big]);
    }
  }

  const byRank = new Map<number, Card[]>();
  for (const card of hand) {
    if (!byRank.has(card.rank)) byRank.set(card.rank, []);
    byRank.get(card.rank)!.push(card);
  }

  for (const [, cards] of byRank) {
    if (cards.length >= 3) {
      for (let i = 0; i < cards.length - 2; i++) {
        plays.push([cards[i], cards[i + 1], cards[i + 2]]);
      }
    }
    if (cards.length >= 4) {
      plays.push([cards[0], cards[1], cards[2], cards[3]]);
    }
  }

  return plays;
}
