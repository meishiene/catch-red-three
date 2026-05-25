import 'types.dart';

TrickStateData createTrickState(List<String> playerOrder, String leaderId, bool isFirstTrick) {
  return TrickStateData(
    boardCards: [],
    boardPlay: null,
    boardPlayerId: null,
    activePlayerIds: Set<String>.from(playerOrder),
    playerOrder: playerOrder,
    currentPlayerIndex: playerOrder.indexOf(leaderId),
    isFirstTrick: isFirstTrick,
  );
}

String getCurrentPlayerId(TrickStateData trick) {
  return trick.playerOrder[trick.currentPlayerIndex];
}

bool isTrickLeader(TrickStateData trick, String playerId) {
  return trick.boardPlayerId == null || trick.boardPlayerId == playerId;
}

BoardState? getBoardState(TrickStateData trick) {
  if (trick.boardCards.isEmpty || trick.boardPlay == null || trick.boardPlayerId == null) {
    return null;
  }
  return BoardState(
    cards: trick.boardCards,
    playType: trick.boardPlay!.type,
    playedByPlayerId: trick.boardPlayerId!,
    isNewTrick: false,
  );
}

void processPlay(TrickStateData trick, String playerId, List<Card> cards, PlayInfo playInfo) {
  trick.boardCards = cards;
  trick.boardPlay = playInfo;
  trick.boardPlayerId = playerId;
  _advanceToNextActivePlayer(trick);
}

String processPass(TrickStateData trick, String playerId) {
  trick.activePlayerIds.remove(playerId);
  _advanceToNextActivePlayer(trick);

  if (trick.activePlayerIds.length <= 1) {
    final winnerId = trick.boardPlayerId ?? trick.activePlayerIds.first;
    return 'TRICK_WON:$winnerId';
  }
  return 'PASSED';
}

void removePlayerFromTrick(TrickStateData trick, String playerId) {
  trick.activePlayerIds.remove(playerId);
}

void resetTrick(TrickStateData trick, String newLeaderId) {
  trick.boardCards = [];
  trick.boardPlay = null;
  trick.boardPlayerId = null;
  trick.currentPlayerIndex = trick.playerOrder.indexOf(newLeaderId);
}

void _advanceToNextActivePlayer(TrickStateData trick) {
  final startIndex = trick.currentPlayerIndex;
  do {
    trick.currentPlayerIndex = (trick.currentPlayerIndex + 1) % trick.playerOrder.length;
    if (trick.currentPlayerIndex == startIndex) break;
  } while (!trick.activePlayerIds.contains(getCurrentPlayerId(trick)));
}
