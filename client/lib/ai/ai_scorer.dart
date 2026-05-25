import 'dart:math';
import '../engine/types.dart';
import '../engine/card.dart';

enum AIDifficulty { EASY, NORMAL, HARD }

double scorePlay(List<Card> play, List<Card> hand, BoardState? boardState,
    AIDifficulty difficulty, List<int> teamCardCounts) {
  switch (difficulty) {
    case AIDifficulty.EASY:
      return Random().nextDouble() * 100;
    case AIDifficulty.NORMAL:
      return _scoreNormal(play, hand);
    case AIDifficulty.HARD:
      return _scoreHard(play, hand, teamCardCounts);
  }
}

double _scoreNormal(List<Card> play, List<Card> hand) {
  double score = 0;
  final playInfo = determinePlay(play);
  if (playInfo == null) return -1;

  final avgPower = play.fold(0.0, (sum, c) => sum + getSingleCardPower(c)) / play.length;
  score += (20 - avgPower) * 2;

  if (playInfo.type == PlayType.BOMB) score -= 10;
  if (playInfo.type == PlayType.BIG_BOMB) score -= 15;
  if (playInfo.type == PlayType.SINGLE) score += 5;
  score += play.length * 2.0;

  return score;
}

double _scoreHard(List<Card> play, List<Card> hand, List<int> teamCardCounts) {
  double score = 0;
  final playInfo = determinePlay(play);
  if (playInfo == null) return -1;

  final avgPower = play.fold(0.0, (sum, c) => sum + getSingleCardPower(c)) / play.length;
  final remainingAfterPlay = hand.length - play.length;

  score += (20 - avgPower) * 1.5;
  if (remainingAfterPlay <= 3) score += 30;
  if (remainingAfterPlay == 0) score += 100;
  score += play.length * 3.0;

  if (playInfo.type == PlayType.JOKER_BOMB) {
    score -= 50;
    if (remainingAfterPlay <= 3) score += 60;
  } else if (playInfo.type == PlayType.BOMB || playInfo.type == PlayType.BIG_BOMB) {
    if (remainingAfterPlay <= 3) score += 40;
    if (hand.length > 10) score -= 20;
  }

  if (teamCardCounts.isNotEmpty) {
    final minTeamCards = teamCardCounts.reduce(min);
    if (minTeamCards <= 3) score += 10;
  }

  return score;
}

bool shouldPass(AIDifficulty difficulty, bool isTrickLeader, BoardState? boardState, int handSize) {
  if (isTrickLeader && boardState == null) return false;
  switch (difficulty) {
    case AIDifficulty.EASY:
      return Random().nextDouble() < 0.5;
    case AIDifficulty.NORMAL:
      return false;
    case AIDifficulty.HARD:
      return handSize > 8 && boardState != null && Random().nextDouble() < 0.2;
  }
}

List<String> shouldRevealIdentity(List<Card> canReveal, List<Card> mustReveal, AIDifficulty difficulty) {
  final toReveal = <String>[];
  toReveal.addAll(mustReveal.map((c) => c.id));
  switch (difficulty) {
    case AIDifficulty.EASY:
      for (final card in canReveal) {
        if (Random().nextDouble() < 0.3) toReveal.add(card.id);
      }
      break;
    case AIDifficulty.NORMAL:
    case AIDifficulty.HARD:
      toReveal.addAll(canReveal.map((c) => c.id));
      break;
  }
  return toReveal;
}

Card chooseTributeReturnCard(List<Card> hand, AIDifficulty difficulty) {
  switch (difficulty) {
    case AIDifficulty.EASY:
    case AIDifficulty.NORMAL:
      return hand[Random().nextInt(hand.length)];
    case AIDifficulty.HARD:
      return hand.reduce((min, c) => getSingleCardPower(c) < getSingleCardPower(min) ? c : min);
  }
}
