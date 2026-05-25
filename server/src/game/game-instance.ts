import {
  Card, GamePhase, Team, GameResult, TrickState, BoardState, TributePair,
} from '../engine/types';
import { PlayInfo } from '../engine/types';
import {
  createTrickState, processPlay, processPass, removePlayerFromTrick,
  resetTrick, getCurrentPlayerId, getBoardState, isTrickLeader,
} from '../engine/trick-manager';
import {
  determinePlay, isValidOpeningPlay, getRevealEligibility, applyReveal, canBeat,
} from '../engine/card';
import { deal, findRedFiveHolder } from '../engine/deck';
import { assignTeams, getTeamMembers } from '../engine/team-assigner';
import { determineWinner, isGameOver } from '../engine/win-detector';
import {
  determineTributePairs, applyTributeGive,
} from '../engine/tribute';
import { TurnTimer } from './turn-timer';
import { config } from '../config';
import { GameStateSnapshot, BoardStatePayload } from '../types/events';
import { AIDifficulty } from '../ai/ai-scorer';
import {
  decideAI, aiRevealDecision, aiTributeReturnCard, aiSelectOpeningPlay,
} from '../ai/ai-engine';

type EventCallback = (event: string, data: any) => void;

export class GameInstance {
  roomCode: string;
  phase: GamePhase;
  players: { id: string; name: string; isAI: boolean }[];
  playerOrder: string[];
  hands: Map<string, Card[]>;
  teams: Map<string, Team>;
  revealedCards: { playerId: string; cardId: string }[];
  trickState: TrickState;
  finishOrder: string[];
  turnTimer: TurnTimer;
  private eventCallback: EventCallback;
  private maxPlayers: number;
  private isFirstRound: boolean;
  private lastGameResult: GameResult | null;
  private tributePairs: TributePair[];
  private currentTributeIndex: number;
  private pendingTributeReturns: Map<string, Card>;
  private firstDealtIndex: number;
  private pendingAIReveals: string[];

  constructor(
    roomCode: string,
    players: { id: string; name: string; isAI: boolean }[],
    maxPlayers: number,
    eventCallback: EventCallback
  ) {
    this.roomCode = roomCode;
    this.phase = GamePhase.WAITING;
    this.players = players;
    this.playerOrder = players.map((p) => p.id);
    this.maxPlayers = maxPlayers;
    this.hands = new Map();
    this.teams = new Map();
    this.revealedCards = [];
    this.finishOrder = [];
    this.turnTimer = new TurnTimer();
    this.eventCallback = eventCallback;
    this.isFirstRound = true;
    this.lastGameResult = null;
    this.tributePairs = [];
    this.currentTributeIndex = 0;
    this.pendingTributeReturns = new Map();
    this.firstDealtIndex = 0;
    this.pendingAIReveals = [];
    this.trickState = createTrickState([], '', false);
  }

  start(): void {
    this.phase = GamePhase.DEALING;

    this.eventCallback('game:starting', { countdown: 3 });

    setTimeout(() => {
      this.dealAndStart();
    }, config.gameStartCountdownMs);
  }

  private dealAndStart(): void {
    let dealerIndex = this.firstDealtIndex;
    if (!this.isFirstRound && this.lastGameResult) {
      const firstFinisherIdx = this.playerOrder.indexOf(this.lastGameResult.firstFinisherId);
      dealerIndex = firstFinisherIdx >= 0 ? firstFinisherIdx : Math.floor(Math.random() * this.maxPlayers);
    } else {
      dealerIndex = Math.floor(Math.random() * this.maxPlayers);
    }

    const dealtHands = deal(this.maxPlayers, dealerIndex);
    this.hands.clear();
    this.teams.clear();
    this.revealedCards = [];
    this.finishOrder = [];

    for (let i = 0; i < this.playerOrder.length; i++) {
      this.hands.set(this.playerOrder[i], dealtHands[i]);
    }

    this.teams = assignTeams(this.hands);

    // Send each player their hand
    for (const player of this.players) {
      this.eventCallback('game:dealt', {
        hand: this.serializeCards(this.hands.get(player.id) || []),
        totalPlayers: this.maxPlayers,
        targetPlayerId: player.id,
      });
    }

    // After dealing, determine if tribute is needed
    if (!this.isFirstRound && this.lastGameResult && this.lastGameResult.winner !== 'draw') {
      this.phase = GamePhase.TRIBUTE;
      this.startTributePhase();
    } else {
      this.phase = GamePhase.IDENTITY_REVEAL;
      this.startIdentityPhase();
    }
  }

  private startTributePhase(): void {
    this.tributePairs = determineTributePairs(
      this.lastGameResult!,
      this.teams,
      this.hands,
      this.maxPlayers
    );

    if (this.tributePairs.length === 0) {
      this.finishTributePhase();
      return;
    }

    this.currentTributeIndex = 0;
    this.pendingTributeReturns.clear();

    this.eventCallback('game:tribute-phase', {
      pairs: this.tributePairs.map((p) => ({
        fromPlayerId: p.fromPlayerId,
        toPlayerId: p.toPlayerId,
      })),
    });

    this.processNextTributeGive();
  }

  private processNextTributeGive(): void {
    if (this.currentTributeIndex >= this.tributePairs.length) {
      return;
    }

    const pair = this.tributePairs[this.currentTributeIndex];
    const card = applyTributeGive(this.hands, pair);

    if (card) {
      // Notify about the tribute card given
      this.eventCallback('game:tribute-phase', {
        cardGiven: {
          fromPlayerId: pair.fromPlayerId,
          cardId: card.id,
        },
        targetPlayerId: pair.toPlayerId,
      });

      // Now winner needs to choose return card
      const winnerPlayer = this.players.find((p) => p.id === pair.toPlayerId);
      if (winnerPlayer?.isAI) {
        const hand = this.hands.get(pair.toPlayerId) || [];
        const returnCard = aiTributeReturnCard(hand, AIDifficulty.NORMAL);
        this.handleTributeReturn(pair.toPlayerId, [returnCard.id]);
      } else {
        // Request human player to choose return card
        this.eventCallback('game:tribute-return-request', {
          targetPlayerId: pair.toPlayerId,
          fromPlayerId: pair.fromPlayerId,
          pairIndex: this.currentTributeIndex,
        });
      }
    }
  }

  handleTributeReturn(playerId: string, returnCardIds: string[]): void {
    if (this.phase !== GamePhase.TRIBUTE) return;

    const pair = this.tributePairs[this.currentTributeIndex];
    if (!pair || pair.toPlayerId !== playerId) return;

    const hand = this.hands.get(playerId);
    if (!hand) return;

    const returnCard = hand.find((c) => c.id === returnCardIds[0]);
    if (!returnCard) return;

    // Remove return card from winner's hand
    const idx = hand.findIndex((c) => c.id === returnCard.id);
    hand.splice(idx, 1);

    // Add loser's tribute card to winner
    if (pair.cardFromLoser) {
      hand.push(pair.cardFromLoser);
    }

    // Add return card to loser
    const loserHand = this.hands.get(pair.fromPlayerId);
    if (loserHand) {
      loserHand.push(returnCard);
    }

    pair.cardFromWinner = returnCard;

    this.eventCallback('game:tribute-complete', {
      pairIndex: this.currentTributeIndex,
      fromPlayerId: pair.fromPlayerId,
      toPlayerId: pair.toPlayerId,
    });

    this.currentTributeIndex++;
    if (this.currentTributeIndex >= this.tributePairs.length) {
      this.finishTributePhase();
    } else {
      this.processNextTributeGive();
    }
  }

  private finishTributePhase(): void {
    this.phase = GamePhase.IDENTITY_REVEAL;
    this.startIdentityPhase();
  }

  private startIdentityPhase(): void {
    this.pendingAIReveals = [];

    for (const player of this.players) {
      const hand = this.hands.get(player.id) || [];
      const eligibility = getRevealEligibility(hand, this.maxPlayers);

      this.eventCallback('game:identity-phase', {
        targetPlayerId: player.id,
        eligibleCards: [...eligibility.mustReveal, ...eligibility.canReveal].map((c) => ({
          id: c.id,
          suit: c.suit,
          rank: c.rank,
        })),
        mustReveal: eligibility.mustReveal.map((c) => c.id),
        canReveal: eligibility.canReveal.map((c) => c.id),
        timeoutMs: config.identityRevealTimeoutMs,
      });

      if (player.isAI) {
        this.pendingAIReveals.push(player.id);
      }
    }

    // Process AI reveals immediately
    for (const aiId of this.pendingAIReveals) {
      const hand = this.hands.get(aiId) || [];
      const eligibility = getRevealEligibility(hand, this.maxPlayers);
      const toReveal = aiRevealDecision(
        hand,
        eligibility.canReveal,
        eligibility.mustReveal,
        AIDifficulty.NORMAL
      );
      if (toReveal.length > 0) {
        this.handleReveal(aiId, toReveal);
      } else {
        this.handleSkipReveal(aiId);
      }
    }
    this.pendingAIReveals = [];

    // Set timeout for human players
    let allResolved = this.pendingAIReveals.length === 0 &&
      this.players.filter((p) => !p.isAI).length === 0;

    if (!allResolved) {
      this.turnTimer.start(config.identityRevealTimeoutMs, () => {
        this.finishIdentityPhase();
      });
    } else {
      this.finishIdentityPhase();
    }
  }

  handleReveal(playerId: string, cardIds: string[]): void {
    if (this.phase !== GamePhase.IDENTITY_REVEAL) return;

    const hand = this.hands.get(playerId);
    if (!hand) return;

    const eligibility = getRevealEligibility(hand, this.maxPlayers);
    const allRevealable = [...eligibility.mustReveal, ...eligibility.canReveal];

    for (const cardId of cardIds) {
      const card = allRevealable.find((c) => c.id === cardId);
      if (card) {
        applyReveal(hand, [cardId]);
        this.revealedCards.push({ playerId, cardId });
      }
    }

    this.eventCallback('game:identity-revealed', {
      playerId,
      cardIds,
    });

    this.checkIdentityPhaseComplete();
  }

  handleSkipReveal(playerId: string): void {
    if (this.phase !== GamePhase.IDENTITY_REVEAL) return;

    this.eventCallback('game:identity-revealed', {
      playerId,
      cardIds: [],
    });

    this.checkIdentityPhaseComplete();
  }

  private checkIdentityPhaseComplete(): void {
    // Start playing phase immediately after all reveals processed
    // (identity phase ends once first trick starts)
    if (this.phase === GamePhase.IDENTITY_REVEAL) {
      this.finishIdentityPhase();
    }
  }

  private finishIdentityPhase(): void {
    this.turnTimer.cancel();

    this.eventCallback('game:identity-phase-end', {
      revealed: this.revealedCards,
    });

    this.phase = GamePhase.PLAYING;
    this.startPlaying();
  }

  private startPlaying(): void {
    const redFiveHolder = findRedFiveHolder(this.hands);
    const firstLeader = redFiveHolder || this.playerOrder[0];

    this.trickState = createTrickState(
      this.playerOrder.filter((id) => !this.finishOrder.includes(id)),
      firstLeader,
      this.isFirstRound
    );

    this.eventCallback('game:trick-start', {
      leaderPlayerId: firstLeader,
      isFirstTrick: this.isFirstRound,
    });

    this.requestTurn(firstLeader);
  }

  private requestTurn(playerId: string): void {
    const hand = this.hands.get(playerId) || [];
    const board = getBoardState(this.trickState);
    const player = this.players.find((p) => p.id === playerId);
    const isLeader = isTrickLeader(this.trickState, playerId);

    this.eventCallback('game:turn-request', {
      targetPlayerId: playerId,
      board: board ? this.serializeBoardState(board) : null,
      timeoutMs: config.turnTimeoutMs,
      isFirstTrick: this.trickState.isFirstTrick,
      isTrickLeader: isLeader,
    });

    if (player?.isAI) {
      // Delay AI play slightly for natural feel
      setTimeout(() => {
        this.handleAITurn(playerId);
      }, 1000 + Math.random() * 2000);
    } else {
      this.turnTimer.start(config.turnTimeoutMs, () => {
        this.autoPass(playerId);
      });
    }
  }

  private handleAITurn(playerId: string): void {
    if (this.phase !== GamePhase.PLAYING) return;
    if (getCurrentPlayerId(this.trickState) !== playerId) return;

    const hand = this.hands.get(playerId) || [];
    const board = getBoardState(this.trickState);
    const team = this.teams.get(playerId) || 'black';
    const teamMembers = getTeamMembers(this.teams, team);
    const teamCardCounts = teamMembers
      .filter((id) => id !== playerId)
      .map((id) => this.hands.get(id)?.length || 0);

    const difficulty = this.getAIDifficulty();

    const isLeader = isTrickLeader(this.trickState, playerId);

    // Handle first trick opening
    if (this.isFirstRound && isLeader) {
      const fives = aiSelectOpeningPlay(hand, difficulty);
      if (fives.length > 0) {
        this.handlePlay(playerId, fives.map((c) => c.id));
        return;
      }
    }

    const decision = decideAI(
      hand,
      board,
      difficulty,
      isLeader,
      this.trickState.isFirstTrick,
      team,
      teamCardCounts
    );

    if (decision.action === 'pass') {
      this.handlePass(playerId);
    } else if (decision.cards) {
      this.handlePlay(playerId, decision.cards.map((c) => c.id));
    }
  }

  private getAIDifficulty(): AIDifficulty {
    // Use NORMAL difficulty for AI fill-ins; players can override
    return AIDifficulty.NORMAL;
  }

  handlePlay(playerId: string, cardIds: string[]): void {
    if (this.phase !== GamePhase.PLAYING) return;
    if (getCurrentPlayerId(this.trickState) !== playerId) return;

    const hand = this.hands.get(playerId);
    if (!hand) return;

    const selectedCards = cardIds
      .map((id) => hand.find((c) => c.id === id))
      .filter((c): c is Card => c !== undefined);

    if (selectedCards.length !== cardIds.length) return;

    const playInfo = determinePlay(selectedCards);
    if (!playInfo) return;

    // Validate opening play
    const isLeader = isTrickLeader(this.trickState, playerId);
    if (this.isFirstRound && isLeader) {
      if (!isValidOpeningPlay(hand, selectedCards)) return;
    }

    // Validate can beat
    const board = getBoardState(this.trickState);
    if (board && !isLeader) {
      const boardPlay = determinePlay(board.cards);
      if (boardPlay) {
        if (!canBeat(playInfo, boardPlay)) return;
      }
    }

    // Apply play: remove cards from hand
    for (const card of selectedCards) {
      const idx = hand.findIndex((c) => c.id === card.id);
      if (idx !== -1) hand.splice(idx, 1);
    }

    processPlay(this.trickState, playerId, selectedCards, playInfo);

    this.eventCallback('game:cards-played', {
      playerId,
      cards: this.serializeCards(selectedCards),
      playType: playInfo.type,
    });

    // Broadcast remaining counts
    for (const p of this.players) {
      this.eventCallback('game:cards-remaining', {
        targetPlayerId: p.id,
        playerId,
        count: this.hands.get(p.id)?.length || 0,
      });
    }

    // Check if player finished
    if (hand.length === 0) {
      this.finishOrder.push(playerId);
      removePlayerFromTrick(this.trickState, playerId);

      this.eventCallback('game:player-finished', {
        playerId,
        position: this.finishOrder.length,
      });
    }

    // Check game over
    const unfinishedCount = this.playerOrder.filter(
      (id) => !this.finishOrder.includes(id)
    ).length;

    if (unfinishedCount <= 1) {
      if (unfinishedCount === 1) {
        const lastPlayer = this.playerOrder.find(
          (id) => !this.finishOrder.includes(id)
        );
        if (lastPlayer) this.finishOrder.push(lastPlayer);
      }
      this.endGame();
      return;
    }

    this.nextTurn();
  }

  handlePass(playerId: string): void {
    if (this.phase !== GamePhase.PLAYING) return;
    if (getCurrentPlayerId(this.trickState) !== playerId) return;

    const board = getBoardState(this.trickState);
    if (isTrickLeader(this.trickState, playerId) && board === null) return;

    this.turnTimer.cancel();

    const result = processPass(this.trickState, playerId);

    this.eventCallback('game:player-passed', { playerId });

    if (result.action === 'TRICK_WON' && result.winnerId) {
      this.eventCallback('game:trick-won', {
        playerId: result.winnerId,
      });

      const winner = result.winnerId;
      if (!this.finishOrder.includes(winner)) {
        resetTrick(
          this.trickState,
          winner
        );
        this.trickState.activePlayerIds = new Set(
          this.trickState.playerOrder.filter(
            (id) => !this.finishOrder.includes(id)
          )
        );
        this.trickState.isFirstTrick = false;

        this.eventCallback('game:trick-start', {
          leaderPlayerId: winner,
          isFirstTrick: false,
        });

        this.requestTurn(winner);
      }
    } else {
      this.nextTurn();
    }
  }

  private nextTurn(): void {
    const currentPlayerId = getCurrentPlayerId(this.trickState);

    // Check if trick should be resolved
    if (this.trickState.activePlayerIds.size <= 1) {
      const winnerId = this.trickState.boardPlayerId;
      if (winnerId && !this.finishOrder.includes(winnerId)) {
        this.eventCallback('game:trick-won', { playerId: winnerId });
        resetTrick(this.trickState, winnerId);
        this.trickState.activePlayerIds = new Set(
          this.trickState.playerOrder.filter(
            (id) => !this.finishOrder.includes(id)
          )
        );
        this.trickState.isFirstTrick = false;

        this.eventCallback('game:trick-start', {
          leaderPlayerId: winnerId,
          isFirstTrick: false,
        });

        this.requestTurn(winnerId);
        return;
      }
    }

    this.requestTurn(currentPlayerId);
  }

  private autoPass(playerId: string): void {
    this.handlePass(playerId);
  }

  private endGame(): void {
    this.phase = GamePhase.GAME_OVER;
    this.turnTimer.cancel();

    const result = determineWinner(this.finishOrder, this.teams);

    this.eventCallback('game:over', result);

    this.lastGameResult = result;
    this.isFirstRound = false;
    this.firstDealtIndex = this.playerOrder.indexOf(
      this.finishOrder[0]
    );
  }

  startNewRound(): void {
    this.dealAndStart();
  }

  getSnapshot(playerId: string): GameStateSnapshot {
    const hand = this.hands.get(playerId) || [];
    const board = getBoardState(this.trickState);

    const opponentCardCounts: Record<string, number> = {};
    for (const [id, cards] of this.hands) {
      if (id !== playerId) {
        opponentCardCounts[id] = cards.length;
      }
    }

    return {
      phase: this.phase,
      hand: this.serializeCards(hand),
      board: board ? this.serializeBoardState(board) : null,
      teams: Object.fromEntries(this.teams),
      revealedCards: this.revealedCards,
      finishOrder: this.finishOrder.map((id, i) => ({ playerId: id, position: i + 1 })),
      opponentCardCounts,
      currentTurnPlayerId: this.phase === GamePhase.PLAYING
        ? getCurrentPlayerId(this.trickState) : null,
      turnTimeoutRemainingMs: this.turnTimer.isRunning()
        ? this.turnTimer.getRemainingMs() : null,
      trickLeaderId: this.trickState.boardPlayerId,
      isFirstTrick: this.trickState.isFirstTrick,
    };
  }

  private serializeCards(cards: Card[]): any[] {
    return cards.map((c) => ({
      id: c.id,
      suit: c.suit,
      rank: c.rank,
      isRevealed: c.isRevealed,
    }));
  }

  private serializeBoardState(board: BoardState): BoardStatePayload {
    return {
      cards: this.serializeCards(board.cards),
      playType: board.playType,
      playedByPlayerId: board.playedByPlayerId,
      isNewTrick: board.isNewTrick,
    };
  }
}
