import 'types.dart';

const Map<Rank, int> rankPower = {
  Rank.FIVE: 5, Rank.SIX: 6, Rank.SEVEN: 7, Rank.EIGHT: 8,
  Rank.NINE: 9, Rank.TEN: 10, Rank.JACK: 11, Rank.QUEEN: 12,
  Rank.KING: 13, Rank.ACE: 14, Rank.TWO: 15, Rank.THREE: 16,
  Rank.FOUR: 17, Rank.SMALL_JOKER: 18, Rank.BIG_JOKER: 19,
};

const double revealedRedThreePower = 17.5;

const Map<PlayType, int> playTypeStrength = {
  PlayType.SINGLE: 1, PlayType.PAIR: 1,
  PlayType.BOMB: 3, PlayType.BIG_BOMB: 4, PlayType.JOKER_BOMB: 5,
};

GameCard createCard(Suit suit, Rank rank) {
  return GameCard(id: '${suit.name}_${rank.value}', suit: suit, rank: rank);
}

double getSingleCardPower(GameCard card) {
  if (card.suit == Suit.JOKER) {
    return card.rank == Rank.BIG_JOKER ? 19 : 18;
  }
  if (card.isRevealed &&
      (card.suit == Suit.H || card.suit == Suit.D) &&
      card.rank == Rank.THREE) {
    return revealedRedThreePower;
  }
  return rankPower[card.rank]!.toDouble();
}

PlayInfo? determinePlay(List<GameCard> cards) {
  final n = cards.length;
  if (n == 0) return null;

  if (n == 1) {
    return PlayInfo(PlayType.SINGLE, getSingleCardPower(cards[0]));
  }

  if (n == 2) {
    final jokers = cards.where((c) => c.suit == Suit.JOKER).toList();
    if (jokers.length == 2) {
      return PlayInfo(PlayType.JOKER_BOMB, 999);
    }
    if (cards[0].rank == cards[1].rank &&
        cards.every((c) => c.suit != Suit.JOKER)) {
      return PlayInfo(PlayType.PAIR, getSingleCardPower(cards[0]));
    }
    return null;
  }

  if (n == 3) {
    final firstRank = cards[0].rank;
    if (cards.every((c) => c.rank == firstRank && c.suit != Suit.JOKER)) {
      return PlayInfo(PlayType.BOMB, getSingleCardPower(cards[0]));
    }
    return null;
  }

  if (n == 4) {
    final firstRank = cards[0].rank;
    if (cards.every((c) => c.rank == firstRank && c.suit != Suit.JOKER)) {
      return PlayInfo(PlayType.BIG_BOMB, getSingleCardPower(cards[0]));
    }
    return null;
  }

  return null;
}

bool canBeat(PlayInfo newPlay, PlayInfo? boardPlay) {
  if (boardPlay == null) return true;
  if (newPlay.type == PlayType.JOKER_BOMB) return true;
  if (boardPlay.type == PlayType.JOKER_BOMB) return false;

  final newStrength = playTypeStrength[newPlay.type]!;
  final boardStrength = playTypeStrength[boardPlay.type]!;

  if (newStrength > boardStrength) return true;
  if (newStrength == boardStrength) {
    if (newPlay.type != boardPlay.type) return false;
    return newPlay.value > boardPlay.value;
  }
  return false;
}

bool isValidOpeningPlay(List<GameCard> hand, List<GameCard> selectedCards) {
  final hasRedFive = selectedCards.any((c) =>
      c.suit == Suit.H && c.rank == Rank.FIVE);
  if (!hasRedFive) return false;
  if (!selectedCards.every((c) => c.rank == Rank.FIVE)) return false;

  final handIds = hand.map((c) => c.id).toSet();
  if (!selectedCards.every((c) => handIds.contains(c.id))) return false;

  return determinePlay(selectedCards) != null;
}

GameCard? findHighestCard(List<GameCard> hand) {
  if (hand.isEmpty) return null;
  return hand.reduce((max, c) =>
      getSingleCardPower(c) > getSingleCardPower(max) ? c : max);
}

Map<String, List<GameCard>> getRevealEligibility(List<GameCard> hand, int maxPlayers) {
  final mustReveal = <GameCard>[];
  final canReveal = <GameCard>[];

  for (final card in hand) {
    if (card.rank != Rank.THREE) continue;
    if (card.suit == Suit.H) {
      canReveal.add(card);
    }
    if (card.suit == Suit.D) {
      if (maxPlayers == 5) {
        mustReveal.add(card);
      } else if (maxPlayers == 4) {
        canReveal.add(card);
      }
    }
  }

  return {'mustReveal': mustReveal, 'canReveal': canReveal};
}

void applyReveal(List<GameCard> hand, List<String> revealedCardIds) {
  for (final card in hand) {
    if (revealedCardIds.contains(card.id)) {
      card.isRevealed = true;
    }
  }
}

int compareCardsDesc(GameCard a, GameCard b) {
  final powerDiff = (getSingleCardPower(b) - getSingleCardPower(a)).toInt();
  if (powerDiff != 0) return powerDiff;
  const suitOrder = {Suit.S: 3, Suit.H: 2, Suit.C: 1, Suit.D: 0, Suit.JOKER: -1};
  return (suitOrder[b.suit] ?? 0) - (suitOrder[a.suit] ?? 0);
}

List<GameCard> sortHand(List<GameCard> hand) {
  final sorted = List<GameCard>.from(hand);
  sorted.sort(compareCardsDesc);
  return sorted;
}
