import 'types.dart';

Map<String, String> assignTeams(Map<String, List<GameCard>> hands) {
  final teams = <String, String>{};
  final redThreeHolders = <String>[];

  for (final entry in hands.entries) {
    final hasRedThree = entry.value.any((c) =>
        (c.suit == Suit.H || c.suit == Suit.D) && c.rank == Rank.THREE);
    if (hasRedThree) redThreeHolders.add(entry.key);
  }

  for (final playerId in hands.keys) {
    teams[playerId] = redThreeHolders.contains(playerId) ? 'red' : 'black';
  }
  return teams;
}

List<String> getTeamMembers(Map<String, String> teams, String team) {
  return teams.entries
      .where((e) => e.value == team)
      .map((e) => e.key)
      .toList();
}
