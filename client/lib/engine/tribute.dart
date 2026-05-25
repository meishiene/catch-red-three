import 'types.dart';
import 'card.dart';
import 'team_assigner.dart';

class TributePair {
  final String fromPlayerId;
  final String toPlayerId;
  Card? cardFromLoser;
  Card? cardFromWinner;
  TributePair({required this.fromPlayerId, required this.toPlayerId});
}

List<TributePair> determineTributePairs(
  GameResult gameResult,
  Map<String, String> teams,
  Map<String, List<Card>> hands,
  int maxPlayers,
) {
  if (gameResult.winner == 'draw') return [];

  final loserTeam = gameResult.winner == 'red' ? 'black' : 'red';
  final winners = getTeamMembers(teams, gameResult.winner);
  final losers = getTeamMembers(teams, loserTeam);
  final pairs = <TributePair>[];

  if (maxPlayers == 3) {
    if (gameResult.winner == 'red') {
      for (final loserId in losers) {
        pairs.add(TributePair(fromPlayerId: loserId, toPlayerId: winners.first));
      }
    } else {
      pairs.add(TributePair(fromPlayerId: losers.first, toPlayerId: gameResult.firstFinisherId));
    }
  } else if (maxPlayers == 4) {
    final shuffledWinners = List<String>.from(winners)..shuffle();
    final shuffledLosers = List<String>.from(losers)..shuffle();
    for (var i = 0; i < shuffledWinners.length && i < shuffledLosers.length; i++) {
      pairs.add(TributePair(fromPlayerId: shuffledLosers[i], toPlayerId: shuffledWinners[i]));
    }
  } else if (maxPlayers == 5) {
    final redThreeHolder = _findHolder(hands, teams, Suit.H);
    final diamondHolder = _findHolder(hands, teams, Suit.D);
    final shuffledLosers = List<String>.from(losers)..shuffle();
    final shuffledWinners = List<String>.from(winners)..shuffle();

    if (gameResult.winner == 'red') {
      if (redThreeHolder != null) {
        for (var i = 0; i < 2 && i < shuffledLosers.length; i++) {
          pairs.add(TributePair(fromPlayerId: shuffledLosers[i], toPlayerId: redThreeHolder));
        }
      }
      if (diamondHolder != null && shuffledLosers.length > 2) {
        pairs.add(TributePair(fromPlayerId: shuffledLosers[2], toPlayerId: diamondHolder));
      }
    } else {
      if (redThreeHolder != null) {
        for (var i = 0; i < 2 && i < shuffledWinners.length; i++) {
          pairs.add(TributePair(fromPlayerId: redThreeHolder, toPlayerId: shuffledWinners[i]));
        }
      }
      if (diamondHolder != null && shuffledWinners.length > 2) {
        pairs.add(TributePair(fromPlayerId: diamondHolder, toPlayerId: shuffledWinners[2]));
      }
    }
  }

  return pairs;
}

String? _findHolder(Map<String, List<Card>> hands, Map<String, String> teams, Suit suit) {
  for (final entry in teams.entries) {
    if (entry.value != 'red') continue;
    final hand = hands[entry.key];
    if (hand == null) continue;
    if (hand.any((c) => c.suit == suit && c.rank == Rank.THREE)) {
      return entry.key;
    }
  }
  return null;
}

Card? applyTributeGive(Map<String, List<Card>> hands, TributePair pair) {
  final loserHand = hands[pair.fromPlayerId];
  if (loserHand == null || loserHand.isEmpty) return null;

  final highest = findHighestCard(loserHand);
  if (highest == null) return null;

  loserHand.removeWhere((c) => c.id == highest.id);
  pair.cardFromLoser = highest;
  return highest;
}

bool applyTributeReceive(Map<String, List<Card>> hands, TributePair pair, Card returnCard) {
  final winnerHand = hands[pair.toPlayerId];
  if (winnerHand == null) return false;

  winnerHand.removeWhere((c) => c.id == returnCard.id);
  pair.cardFromWinner = returnCard;

  if (pair.cardFromLoser != null) {
    winnerHand.add(pair.cardFromLoser!);
  }

  final loserHand = hands[pair.fromPlayerId];
  if (loserHand != null) {
    loserHand.add(returnCard);
  }
  return true;
}
