import 'dart:math';
import 'package:flutter/material.dart';

class TableLayout extends StatelessWidget {
  final Map<String, int> opponentCounts;
  final String? currentTurnPlayerId;
  final List<Map<String, dynamic>> finishOrder;
  final Map<String, String> teams;
  final Map<String, String> playerNames;
  final List<Map<String, dynamic>> revealedCards;

  const TableLayout({
    super.key,
    required this.opponentCounts,
    this.currentTurnPlayerId,
    this.finishOrder = const [],
    this.teams = const {},
    this.revealedCards = const [],
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
              final hasRevealed = revealedCards.any((r) => r['playerId'] == playerId);

              // Semi-circle arc: positions from angle -150 to -30 degrees (top arc)
              final startAngle = -2.7;  // ~ -155 degrees
              final endAngle = -0.45;    // ~ -25 degrees
              final angle = count <= 1
                  ? (startAngle + endAngle) / 2
                  : startAngle + (endAngle - startAngle) * i / (count - 1);
              final radius = tableSize * 0.75;
              final centerX = constraints.maxWidth / 2;
              final centerY = tableSize / 2 + 10;
              final xPos = centerX + radius * cos(angle) - 40;
              final yPos = centerY + radius * sin(angle) - 30;

              return Positioned(
                top: yPos,
                left: xPos,
                child: _OpponentSeat(
                  name: name,
                  cardCount: isFinished ? 0 : entry.value,
                  isActive: isTurn,
                  isFinished: isFinished,
                  team: team,
                  hasRevealed: hasRevealed,
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
  final bool hasRevealed;

  const _OpponentSeat({
    required this.name,
    required this.cardCount,
    required this.isActive,
    required this.isFinished,
    this.team,
    this.hasRevealed = false,
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
          if (hasRevealed)
            const Text('已亮', style: TextStyle(fontSize: 10, color: Colors.orange)),
          if (isFinished)
            const Icon(Icons.check_circle, color: Colors.green, size: 14)
          else
            Text('${cardCount}张', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
