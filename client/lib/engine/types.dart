enum Suit {
  S, // Spade
  H, // Heart
  C, // Club
  D, // Diamond
  JOKER,
}

enum Rank {
  FIVE = 5, SIX = 6, SEVEN = 7, EIGHT = 8, NINE = 9, TEN = 10,
  JACK = 11, QUEEN = 12, KING = 13, ACE = 14, TWO = 15,
  THREE = 16, FOUR = 17, SMALL_JOKER = 18, BIG_JOKER = 19,
}

class Card {
  final String id;
  final Suit suit;
  final Rank rank;
  bool isRevealed;

  Card({required this.id, required this.suit, required this.rank, this.isRevealed = false});

  factory Card.fromJson(Map<String, dynamic> json) => Card(
    id: json['id'] as String,
    suit: Suit.values.firstWhere((s) => s.name == json['suit']),
    rank: Rank.values.firstWhere((r) => r.value == json['rank']),
    isRevealed: json['isRevealed'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'suit': suit.name,
    'rank': rank.value,
    'isRevealed': isRevealed,
  };

  int get rankValue => rank.value;
}

enum PlayType { SINGLE, PAIR, BOMB, BIG_BOMB, JOKER_BOMB }

class PlayInfo {
  final PlayType type;
  final double value;
  PlayInfo(this.type, this.value);
}

enum GamePhase { WAITING, DEALING, TRIBUTE, IDENTITY_REVEAL, PLAYING, GAME_OVER }

class BoardState {
  final List<Card> cards;
  final PlayType playType;
  final String playedByPlayerId;
  final bool isNewTrick;
  BoardState({
    required this.cards,
    required this.playType,
    required this.playedByPlayerId,
    this.isNewTrick = false,
  });
}

class TrickStateData {
  List<Card> boardCards;
  PlayInfo? boardPlay;
  String? boardPlayerId;
  Set<String> activePlayerIds;
  List<String> playerOrder;
  int currentPlayerIndex;
  bool isFirstTrick;

  TrickStateData({
    required this.boardCards,
    this.boardPlay,
    this.boardPlayerId,
    required this.activePlayerIds,
    required this.playerOrder,
    required this.currentPlayerIndex,
    this.isFirstTrick = false,
  });
}

class GameResult {
  final String winner;
  final List<Map<String, dynamic>> finishOrder;
  final List<Map<String, dynamic>> redTeam;
  final List<Map<String, dynamic>> blackTeam;
  final String firstFinisherId;
  final String? caughtPlayerId;
  GameResult({
    required this.winner,
    required this.finishOrder,
    required this.redTeam,
    required this.blackTeam,
    required this.firstFinisherId,
    this.caughtPlayerId,
  });

  factory GameResult.fromJson(Map<String, dynamic> json) => GameResult(
    winner: json['winner'] as String,
    finishOrder: List<Map<String, dynamic>>.from(json['finishOrder']),
    redTeam: List<Map<String, dynamic>>.from(json['redTeam']),
    blackTeam: List<Map<String, dynamic>>.from(json['blackTeam']),
    firstFinisherId: json['firstFinisherId'] as String,
    caughtPlayerId: json['caughtPlayerId'] as String?,
  );
}
