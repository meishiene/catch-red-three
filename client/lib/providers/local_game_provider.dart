import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_state.dart';
import '../engine/types.dart';
import '../engine/card.dart';
import '../engine/local_game_engine.dart';
import '../ai/ai_scorer.dart';
import 'app_provider.dart';

class LocalGameNotifier extends StateNotifier<GameState> {
  late LocalGameEngine _engine;
  Timer? _turnTimer;
  int _remainingSeconds = 60;
  static const _turnDuration = 60;

  LocalGameNotifier() : super(GameState()) {}

  void _startTurnTimer() {
    _cancelTurnTimer();
    _remainingSeconds = _turnDuration;
    state = state.copyWith(turnTimeoutRemainingMs: _remainingSeconds);
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _remainingSeconds--;
      if (_remainingSeconds <= 0) {
        _cancelTurnTimer();
        _engine.handleHumanPass();
      } else {
        state = state.copyWith(turnTimeoutRemainingMs: _remainingSeconds);
      }
    });
  }

  void _cancelTurnTimer() {
    _turnTimer?.cancel();
    _turnTimer = null;
  }

  void startNewGame(int maxPlayers, AIDifficulty difficulty, String playerName) {
    _cancelTurnTimer();
    _engine = LocalGameEngine(
      maxPlayers: maxPlayers,
      difficulty: difficulty,
      onEvent: _handleGameEvent,
    );
    _engine.start();
  }

  void _handleGameEvent(String event, Map<String, dynamic> data) {
    switch (event) {
      case 'game:dealt':
        final hand = (data['hand'] as List).cast<GameCard>();
        final teams = data['teams'] != null
            ? Map<String, String>.from(data['teams'] as Map)
            : <String, String>{};
        final opponentCounts = data['opponentCounts'] != null
            ? Map<String, int>.from(data['opponentCounts'] as Map)
            : <String, int>{};
        final myTeam = data['myTeam'] as String?;
        state = state.copyWith(
          phase: 'DEALT',
          hand: hand,
          teams: teams,
          opponentCardCounts: opponentCounts,
          myTeam: myTeam,
        );
        break;

      case 'game:identity-phase':
        final mustReveal = (data['mustReveal'] as List?)?.cast<GameCard>() ?? [];
        final canReveal = (data['canReveal'] as List?)?.cast<GameCard>() ?? [];
        final revCards = (data['revealedCards'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e))
            .toList() ?? [];
        state = state.copyWith(
          phase: 'IDENTITY_REVEAL',
          mustRevealCards: mustReveal,
          canRevealCards: canReveal,
          revealedCards: revCards,
        );
        break;

      case 'game:trick-start':
        state = state.copyWith(
          phase: 'PLAYING',
          isFirstTrick: data['isFirstTrick'] as bool,
        );
        break;

      case 'game:turn-request':
        BoardState? board;
        if (data['board'] != null) {
          final b = data['board'] as Map<String, dynamic>;
          board = BoardState(
            cards: (b['cards'] as List).cast<GameCard>(),
            playType: PlayType.values.firstWhere((t) => t.name == b['playType']),
            playedByPlayerId: b['playedByPlayerId'] as String,
          );
        }
        state = state.copyWith(
          phase: 'PLAYING',
          board: board,
          currentTurnPlayerId: 'p0',
          isFirstTrick: data['isFirstTrick'] as bool? ?? false,
          trickLeaderId: data['isTrickLeader'] == true ? 'p0' : null,
        );
        _startTurnTimer();
        break;

      case 'game:cards-played':
        _cancelTurnTimer();
        final playerId = data['playerId'] as String;
        final cards = (data['cards'] as List).cast<GameCard>();
        final playType = PlayType.values.firstWhere((t) => t.name == data['playType']);
        state = state.copyWith(
          board: BoardState(cards: cards, playType: playType, playedByPlayerId: playerId),
          currentTurnPlayerId: null,
          turnTimeoutRemainingMs: null,
        );
        // Remove played cards from hand if it was human
        if (playerId == 'p0') {
          final newHand = List<GameCard>.from(state.hand);
          for (final c in cards) {
            newHand.removeWhere((h) => h.id == c.id);
          }
          state = state.copyWith(hand: newHand);
        }
        break;

      case 'game:player-passed':
        _cancelTurnTimer();
        state = state.copyWith(currentTurnPlayerId: null, turnTimeoutRemainingMs: null);
        break;

      case 'game:cards-remaining':
        if (data['counts'] != null) {
          final counts = Map<String, int>.from(data['counts'] as Map);
          state = state.copyWith(opponentCardCounts: counts);
        }
        break;

      case 'game:player-finished':
        final newOrder = List<Map<String, dynamic>>.from(state.finishOrder);
        newOrder.add({'playerId': data['playerId'], 'position': data['position']});
        state = state.copyWith(finishOrder: newOrder);
        break;

      case 'game:over':
        _cancelTurnTimer();
        state = state.copyWith(phase: 'GAME_OVER', gameOverData: data);
        break;

      case 'game:error':
        state = state.copyWith(errorMessage: data['message'] as String?);
        break;

      case 'game:tribute-give':
        state = state.copyWith(
          phase: 'TRIBUTE',
          tributeData: data,
        );
        break;

      case 'game:tribute-return-request':
        state = state.copyWith(
          phase: 'TRIBUTE',
          hand: (data['hand'] as List).cast<GameCard>(),
          tributeData: data,
        );
        break;

      case 'game:tribute-return-done':
        state = state.copyWith(
          hand: (data['hand'] as List).cast<GameCard>(),
          tributeData: null,
        );
        break;

      case 'game:tribute-complete':
        state = state.copyWith(tributeData: null);
        break;

      case 'game:wind-request':
        state = state.copyWith(windData: data);
        break;

      case 'game:wind-agree-request':
        state = state.copyWith(windData: data);
        break;

      case 'game:wind-granted':
        state = state.copyWith(windData: null);
        break;

      case 'game:wind-opposed':
        state = state.copyWith(windData: null);
        break;
    }
  }

  void toggleCardSelection(String cardId) {
    final selected = List<String>.from(state.selectedCardIds);
    if (selected.contains(cardId)) {
      selected.remove(cardId);
    } else {
      selected.add(cardId);
    }
    state = state.copyWith(selectedCardIds: selected);
  }

  void playSelectedCards() {
    if (state.selectedCardIds.isEmpty) return;
    _engine.handleHumanPlay(state.selectedCardIds);
    state = state.copyWith(selectedCardIds: []);
  }

  void pass() {
    _engine.handleHumanPass();
  }

  void reveal(List<String> cardIds) {
    _engine.handleReveal(cardIds);
    state = state.copyWith(phase: 'PLAYING');
  }

  void skipReveal() {
    _engine.handleSkipReveal();
    state = state.copyWith(phase: 'PLAYING');
  }

  void startNewRound() {
    _engine.startNewRound();
  }

  void tributeReturn(String cardId) {
    _engine.handleTributeReturn(cardId);
  }

  void tributeContinue() {
    _engine.handleTributeContinue();
  }

  void handleWindRequest(bool takeWind) {
    _engine.handleWindRequest(takeWind);
  }

  void handleWindAgree(bool agree) {
    _engine.handleWindAgree(agree);
  }

  void clear() {
    _cancelTurnTimer();
    state = GameState();
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final localGameProvider = StateNotifierProvider<LocalGameNotifier, GameState>((ref) {
  return LocalGameNotifier();
});
