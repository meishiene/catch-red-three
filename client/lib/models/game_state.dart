import '../engine/types.dart';

class GameState {
  final String phase;
  final List<GameCard> hand;
  final BoardState? board;
  final Map<String, String> teams;
  final List<Map<String, dynamic>> revealedCards;
  final List<Map<String, dynamic>> finishOrder;
  final Map<String, int> opponentCardCounts;
  final String? currentTurnPlayerId;
  final int? turnTimeoutRemainingMs;
  final String? trickLeaderId;
  final bool isFirstTrick;
  final String? myTeam;
  final List<String> selectedCardIds;
  final List<GameCard> mustRevealCards;
  final List<GameCard> canRevealCards;
  final Map<String, dynamic>? gameOverData;
  final String? errorMessage;

  GameState({
    this.phase = 'WAITING',
    this.hand = const [],
    this.board,
    this.teams = const {},
    this.revealedCards = const [],
    this.finishOrder = const [],
    this.opponentCardCounts = const {},
    this.currentTurnPlayerId,
    this.turnTimeoutRemainingMs,
    this.trickLeaderId,
    this.isFirstTrick = false,
    this.myTeam,
    this.selectedCardIds = const [],
    this.mustRevealCards = const [],
    this.canRevealCards = const [],
    this.gameOverData,
    this.errorMessage,
  });

  GameState copyWith({
    String? phase,
    List<GameCard>? hand,
    BoardState? board,
    Map<String, String>? teams,
    List<Map<String, dynamic>>? revealedCards,
    List<Map<String, dynamic>>? finishOrder,
    Map<String, int>? opponentCardCounts,
    String? currentTurnPlayerId,
    int? turnTimeoutRemainingMs,
    String? trickLeaderId,
    bool? isFirstTrick,
    String? myTeam,
    List<String>? selectedCardIds,
    List<GameCard>? mustRevealCards,
    List<GameCard>? canRevealCards,
    Map<String, dynamic>? gameOverData,
    String? errorMessage,
  }) {
    return GameState(
      phase: phase ?? this.phase,
      hand: hand ?? this.hand,
      board: board ?? this.board,
      teams: teams ?? this.teams,
      revealedCards: revealedCards ?? this.revealedCards,
      finishOrder: finishOrder ?? this.finishOrder,
      opponentCardCounts: opponentCardCounts ?? this.opponentCardCounts,
      currentTurnPlayerId: currentTurnPlayerId ?? this.currentTurnPlayerId,
      turnTimeoutRemainingMs: turnTimeoutRemainingMs ?? this.turnTimeoutRemainingMs,
      trickLeaderId: trickLeaderId ?? this.trickLeaderId,
      isFirstTrick: isFirstTrick ?? this.isFirstTrick,
      myTeam: myTeam ?? this.myTeam,
      selectedCardIds: selectedCardIds ?? this.selectedCardIds,
      mustRevealCards: mustRevealCards ?? this.mustRevealCards,
      canRevealCards: canRevealCards ?? this.canRevealCards,
      gameOverData: gameOverData ?? this.gameOverData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isMyTurn => currentTurnPlayerId != null;
  bool get isTrickLeader => trickLeaderId != null;
}
