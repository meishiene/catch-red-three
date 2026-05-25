import '../engine/types.dart';
import '../engine/card.dart';
import '../engine/play_validator.dart';
import 'ai_scorer.dart';

class AIDecision {
  final String action;
  final List<Card>? cards;
  AIDecision({required this.action, this.cards});
}

AIDecision decideAI(
  List<Card> hand,
  BoardState? boardState,
  AIDifficulty difficulty,
  bool isTrickLeader,
  List<int> teamCardCounts,
) {
  final legalPlays = getAllLegalPlays(hand, boardState);
  if (legalPlays.isEmpty) return AIDecision(action: 'pass');

  if (shouldPass(difficulty, isTrickLeader, boardState, hand.length)) {
    return AIDecision(action: 'pass');
  }

  final scored = legalPlays.map((cards) {
    final s = scorePlay(cards, hand, boardState, difficulty, teamCardCounts);
    return MapEntry(cards, s);
  }).toList();

  scored.sort((a, b) => b.value.compareTo(a.value));
  return AIDecision(action: 'play', cards: scored.first.key);
}

List<Card> aiSelectOpeningPlay(List<Card> hand, AIDifficulty difficulty) {
  final fives = hand.where((c) => c.rank == Rank.FIVE).toList();
  if (difficulty == AIDifficulty.EASY) return [fives.first];
  if (difficulty == AIDifficulty.NORMAL) {
    if (fives.length >= 4) return fives.sublist(0, 4);
    if (fives.length == 3) return fives.sublist(0, 3);
    if (fives.length >= 2) return fives.sublist(0, 2);
    return [fives.first];
  }
  return [fives.first];
}
