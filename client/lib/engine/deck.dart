import 'dart:math';
import 'types.dart';
import 'card.dart';

List<Card> createDeck() {
  final suits = [Suit.S, Suit.H, Suit.C, Suit.D];
  final ranks = [
    Rank.FIVE, Rank.SIX, Rank.SEVEN, Rank.EIGHT, Rank.NINE, Rank.TEN,
    Rank.JACK, Rank.QUEEN, Rank.KING, Rank.ACE, Rank.TWO, Rank.THREE, Rank.FOUR,
  ];

  final deck = <Card>[];
  for (final suit in suits) {
    for (final rank in ranks) {
      deck.add(createCard(suit, rank));
    }
  }
  deck.add(createCard(Suit.JOKER, Rank.SMALL_JOKER));
  deck.add(createCard(Suit.JOKER, Rank.BIG_JOKER));
  return deck;
}

List<Card> shuffleDeck(List<Card> deck) {
  final shuffled = List<Card>.from(deck);
  final rng = Random();
  for (var i = shuffled.length - 1; i > 0; i--) {
    final j = rng.nextInt(i + 1);
    final temp = shuffled[i];
    shuffled[i] = shuffled[j];
    shuffled[j] = temp;
  }
  return shuffled;
}

List<List<Card>> deal(int numPlayers, int firstDealtPlayerIndex) {
  final deck = shuffleDeck(createDeck());
  final hands = List.generate(numPlayers, (_) => <Card>[]);

  for (var i = 0; i < deck.length; i++) {
    final playerIdx = (firstDealtPlayerIndex + i) % numPlayers;
    hands[playerIdx].add(deck[i]);
  }

  for (final hand in hands) {
    hand.sort(compareCardsDesc);
  }

  return hands;
}

String? findRedFiveHolder(Map<String, List<Card>> hands) {
  for (final entry in hands.entries) {
    final hasRedFive = entry.value.any((c) =>
        c.suit == Suit.H && c.rank == Rank.FIVE);
    if (hasRedFive) return entry.key;
  }
  return null;
}
