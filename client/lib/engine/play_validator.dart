import 'types.dart';
import 'card.dart';

class PlayValidationResult {
  final bool valid;
  final String? error;
  final PlayInfo? playInfo;
  PlayValidationResult({required this.valid, this.error, this.playInfo});
}

PlayValidationResult validatePlay(
  List<Card> selectedCards,
  List<Card> playerHand,
  BoardState? boardState,
  bool isFirstTrick,
  bool isTrickLeader,
) {
  final handIds = playerHand.map((c) => c.id).toSet();
  for (final card in selectedCards) {
    if (!handIds.contains(card.id)) {
      return PlayValidationResult(valid: false, error: '选中的牌不在手中');
    }
  }

  final selectedIds = selectedCards.map((c) => c.id).toSet();
  if (selectedIds.length != selectedCards.length) {
    return PlayValidationResult(valid: false, error: '不能重复选择同一张牌');
  }

  final playInfo = determinePlay(selectedCards);
  if (playInfo == null) {
    return PlayValidationResult(valid: false, error: '无效的牌型组合');
  }

  if (isFirstTrick && isTrickLeader) {
    if (!isValidOpeningPlay(playerHand, selectedCards)) {
      return PlayValidationResult(valid: false, error: '第一手必须包含红桃5且全部为5');
    }
    return PlayValidationResult(valid: true, playInfo: playInfo);
  }

  if (boardState == null || isTrickLeader) {
    return PlayValidationResult(valid: true, playInfo: playInfo);
  }

  final boardPlay = determinePlay(boardState.cards);
  if (boardPlay == null) {
    return PlayValidationResult(valid: false, error: '桌面牌型异常');
  }

  if (!canBeat(playInfo, boardPlay)) {
    return PlayValidationResult(valid: false, error: '打不过当前桌面的牌');
  }

  return PlayValidationResult(valid: true, playInfo: playInfo);
}

List<List<Card>> getAllLegalPlays(List<Card> hand, BoardState? boardState) {
  final allPlays = _getAllPossiblePlays(hand);
  if (boardState == null) return allPlays;

  final boardPlay = determinePlay(boardState.cards);
  if (boardPlay == null) return [];

  return allPlays.where((cards) {
    final info = determinePlay(cards);
    return info != null && canBeat(info, boardPlay);
  }).toList();
}

List<List<Card>> _getAllPossiblePlays(List<Card> hand) {
  final plays = <List<Card>>[];
  final n = hand.length;

  for (var i = 0; i < n; i++) {
    plays.add([hand[i]]);
  }

  for (var i = 0; i < n; i++) {
    for (var j = i + 1; j < n; j++) {
      if (hand[i].rank == hand[j].rank) {
        plays.add([hand[i], hand[j]]);
      }
    }
  }

  final jokers = hand.where((c) => c.suit == Suit.JOKER).toList();
  if (jokers.length >= 2) {
    final small = jokers.where((c) => c.rank == Rank.SMALL_JOKER).firstOrNull;
    final big = jokers.where((c) => c.rank == Rank.BIG_JOKER).firstOrNull;
    if (small != null && big != null) {
      plays.add([small, big]);
    }
  }

  final byRank = <int, List<Card>>{};
  for (final card in hand) {
    byRank.putIfAbsent(card.rankValue, () => []).add(card);
  }

  for (final cards in byRank.values) {
    if (cards.length >= 3) {
      plays.add([cards[0], cards[1], cards[2]]);
    }
    if (cards.length >= 4) {
      plays.add([cards[0], cards[1], cards[2], cards[3]]);
    }
  }

  return plays;
}

extension on Iterable<Card> {
  Card? get firstOrNull => isEmpty ? null : first;
}
