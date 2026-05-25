import 'types.dart';

GameResult determineWinner(List<String> finishOrder, Map<String, String> teams) {
  final firstFinisherId = finishOrder.first;
  final lastFinisherId = finishOrder.last;
  final firstTeam = teams[firstFinisherId]!;
  final lastTeam = teams[lastFinisherId]!;

  final finishOrderResult = finishOrder.asMap().entries.map((e) => {
    'playerId': e.value,
    'position': e.key + 1,
  }).toList();

  final redTeam = <Map<String, dynamic>>[];
  final blackTeam = <Map<String, dynamic>>[];

  for (final entry in teams.entries) {
    final isCaught = entry.key == lastFinisherId;
    if (entry.value == 'red') {
      redTeam.add({'playerId': entry.key, 'isCaught': isCaught});
    } else {
      blackTeam.add({'playerId': entry.key, 'isCaught': isCaught});
    }
  }

  String winner;
  if (firstTeam != lastTeam) {
    winner = firstTeam;
  } else {
    winner = 'draw';
  }

  return GameResult(
    winner: winner,
    finishOrder: finishOrderResult,
    redTeam: redTeam,
    blackTeam: blackTeam,
    firstFinisherId: firstFinisherId,
    caughtPlayerId: winner != 'draw' ? lastFinisherId : null,
  );
}

bool isGameOver(int unfinishedCount) {
  return unfinishedCount <= 1;
}
