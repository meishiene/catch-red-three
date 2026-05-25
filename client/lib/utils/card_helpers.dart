import '../engine/card.dart';
import '../engine/types.dart';

String getCardImagePath(GameCard card) {
  final suitMap = {
    Suit.S: 'S', Suit.H: 'H', Suit.C: 'C', Suit.D: 'D', Suit.JOKER: 'JOKER',
  };
  return 'assets/images/cards/${suitMap[card.suit]}_${card.rank.value}.png';
}

String getCardDisplayName(GameCard card) {
  if (card.suit == Suit.JOKER) {
    return card.rank == Rank.BIG_JOKER ? '大王' : '小王';
  }
  final suitNames = {Suit.S: '♠', Suit.H: '♥', Suit.C: '♣', Suit.D: '♦'};
  final rankNames = {
    5: '5', 6: '6', 7: '7', 8: '8', 9: '9', 10: '10',
    11: 'J', 12: 'Q', 13: 'K', 14: 'A', 15: '2', 16: '3', 17: '4',
  };
  return '${suitNames[card.suit]}${rankNames[card.rankValue]}';
}

String playTypeToString(PlayType type) {
  switch (type) {
    case PlayType.SINGLE: return '单张';
    case PlayType.PAIR: return '对子';
    case PlayType.BOMB: return '炸弹';
    case PlayType.BIG_BOMB: return '大炸弹';
    case PlayType.JOKER_BOMB: return '王炸';
  }
}
