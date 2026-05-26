import 'package:flutter/material.dart';

class TableLayout extends StatelessWidget {
  final Map<String, int> opponentCounts;
  final String? currentTurnPlayerId;
  final List<Map<String, dynamic>> finishOrder;
  final Map<String, String> teams;
  final Map<String, String> playerNames;

  const TableLayout({
    super.key,
    required this.opponentCounts,
    this.currentTurnPlayerId,
    this.finishOrder = const [],
    this.teams = const {},
    this.playerNames = const {},
  });

  @override
  Widget build(BuildContext context) {
    final opponents = opponentCounts.entries.toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableSize = constraints.maxWidth * 0.35;
        final count = opponents.length;

        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: tableSize,
              height: tableSize,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.3),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF4CAF50), width: 2),
              ),
            ),
            ...List.generate(count, (i) {
              final entry = opponents[i];
              final playerId = entry.key;
              final isFinished = finishOrder.any((f) => f['playerId'] == playerId);
              final isTurn = playerId == currentTurnPlayerId;
              final name = playerNames[playerId] ?? (playerId.length > 4 ? playerId.substring(0, 4) : playerId);
              final team = teams[playerId];

              final double fraction = count <= 1 ? 0.5 : i / (count - 1);
              final leftPadding = 60.0;
              final availableWidth = constraints.maxWidth - leftPadding * 2;
              final xPos = leftPadding + fraction * availableWidth - 40;

              return Positioned(
                top: 8,
                left: xPos,
                child: _OpponentSeat(
                  name: name,
                  cardCount: isFinished ? 0 : entry.value,
                  isActive: isTurn,
                  isFinished: isFinished,
                  team: team,
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _OpponentSeat extends StatelessWidget {
  final String name;
  final int cardCount;
  final bool isActive;
  final bool isFinished;
  final String? team;

  const _OpponentSeat({
    required this.name,
    required this.cardCount,
    required this.isActive,
    required this.isFinished,
    this.team,
  });

  @override
  Widget build(BuildContext context) {
    final isRed = team == 'red';
    final teamColor = team == null
        ? Colors.grey
        : isRed
            ? const Color(0xFFD4380D)
            : Colors.grey;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 80,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFD4380D).withOpacity(0.2)
            : teamColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: isActive
            ? Border.all(color: const Color(0xFFD4380D), width: 2)
            : isRed
                ? Border.all(color: teamColor, width: 1)
                : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: isActive ? const Color(0xFFD4380D) : teamColor,
            child: Text(
              isRed ? '红' : name[0],
              style: const TextStyle(fontSize: 11, color: Colors.white),
            ),
          ),
          const SizedBox(height: 4),
          Text(name, style: const TextStyle(fontSize: 11)),
          if (isFinished)
            const Icon(Icons.check_circle, color: Colors.green, size: 14)
          else
            Text('${cardCount}张', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
