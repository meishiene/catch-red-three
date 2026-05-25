import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_state.dart';
import '../models/room.dart';
import '../services/socket_service.dart';
import '../engine/types.dart';
import '../engine/card.dart';
import 'app_provider.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  throw UnimplementedError('SocketService must be provided externally');
});

class GameNotifier extends StateNotifier<GameState> {
  final SocketService _socket;
  final String _myPlayerId;
  StreamSubscription? _subDealt;
  StreamSubscription? _subIdentityPhase;
  StreamSubscription? _subIdentityRevealed;
  StreamSubscription? _subIdentityPhaseEnd;
  StreamSubscription? _subTrickStart;
  StreamSubscription? _subTurnRequest;
  StreamSubscription? _subCardsPlayed;
  StreamSubscription? _subPlayerPassed;
  StreamSubscription? _subTrickWon;
  StreamSubscription? _subPlayerFinished;
  StreamSubscription? _subCardsRemaining;
  StreamSubscription? _subGameOver;

  GameNotifier(this._socket, this._myPlayerId) : super(GameState()) {
    _setupListeners();
  }

  void _setupListeners() {
    _subDealt = _socket.on<Map<String, dynamic>>('game:dealt').listen((data) {
      final hand = (data['hand'] as List)
          .map((c) => Card.fromJson(c as Map<String, dynamic>))
          .toList();
      state = state.copyWith(phase: 'DEALT', hand: hand);
    });

    _subIdentityPhase = _socket.on<Map<String, dynamic>>('game:identity-phase').listen((data) {
      state = state.copyWith(phase: 'IDENTITY_REVEAL', turnTimeoutRemainingMs: data['timeoutMs'] as int?);
    });

    _subTurnRequest = _socket.on<Map<String, dynamic>>('game:turn-request').listen((data) {
      final isMyTurn = data['targetPlayerId'] == _myPlayerId;
      BoardState? board;
      if (data['board'] != null) {
        final b = data['board'] as Map<String, dynamic>;
        board = BoardState(
          cards: (b['cards'] as List).map((c) => Card.fromJson(c as Map<String, dynamic>)).toList(),
          playType: PlayType.values.firstWhere((t) => t.name == b['playType']),
          playedByPlayerId: b['playedByPlayerId'] as String,
        );
      }
      state = state.copyWith(
        phase: 'PLAYING',
        board: board,
        currentTurnPlayerId: isMyTurn ? _myPlayerId : null,
        turnTimeoutRemainingMs: data['timeoutMs'] as int?,
        isFirstTrick: data['isFirstTrick'] as bool? ?? false,
        trickLeaderId: isMyTurn ? _myPlayerId : null,
      );
    });

    _subCardsPlayed = _socket.on<Map<String, dynamic>>('game:cards-played').listen((data) {
      final playerId = data['playerId'] as String;
      final cards = (data['cards'] as List)
          .map((c) => Card.fromJson(c as Map<String, dynamic>))
          .toList();
      final playType = PlayType.values.firstWhere((t) => t.name == data['playType']);
      state = state.copyWith(
        board: BoardState(cards: cards, playType: playType, playedByPlayerId: playerId),
        currentTurnPlayerId: null,
      );
    });

    _subPlayerPassed = _socket.on<Map<String, dynamic>>('game:player-passed').listen((_) {
      state = state.copyWith(currentTurnPlayerId: null);
    });

    _subPlayerFinished = _socket.on<Map<String, dynamic>>('game:player-finished').listen((data) {
      final newOrder = List<Map<String, dynamic>>.from(state.finishOrder);
      newOrder.add({'playerId': data['playerId'], 'position': data['position']});
      state = state.copyWith(finishOrder: newOrder);
    });

    _subCardsRemaining = _socket.on<Map<String, dynamic>>('game:cards-remaining').listen((data) {
      final newCounts = Map<String, int>.from(state.opponentCardCounts);
      newCounts[data['playerId'] as String] = data['count'] as int;
      state = state.copyWith(opponentCardCounts: newCounts);
    });

    _subGameOver = _socket.on<Map<String, dynamic>>('game:over').listen((data) {
      state = state.copyWith(phase: 'GAME_OVER');
    });
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
    _socket.emit('game:play', {'cardIds': state.selectedCardIds});
    state = state.copyWith(selectedCardIds: []);
  }

  void pass() {
    _socket.emit('game:pass');
  }

  void reveal(List<String> cardIds) {
    _socket.emit('game:reveal', {'cardIds': cardIds});
  }

  void skipReveal() {
    _socket.emit('game:skip-reveal');
  }

  @override
  void dispose() {
    _subDealt?.cancel();
    _subIdentityPhase?.cancel();
    _subIdentityRevealed?.cancel();
    _subIdentityPhaseEnd?.cancel();
    _subTrickStart?.cancel();
    _subTurnRequest?.cancel();
    _subCardsPlayed?.cancel();
    _subPlayerPassed?.cancel();
    _subTrickWon?.cancel();
    _subPlayerFinished?.cancel();
    _subCardsRemaining?.cancel();
    _subGameOver?.cancel();
    super.dispose();
  }
}
