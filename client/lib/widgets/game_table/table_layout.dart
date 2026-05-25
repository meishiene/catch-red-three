import 'package:flutter/material.dart';

class TableLayout extends StatelessWidget {
  final Map<String, int> opponentCounts;
  final String? currentTurnPlayerId;
  final List<Map<String, dynamic>> finishOrder;

  const TableLayout({
    super.key,
    required this.opponentCounts,
    this.currentTurnPlayerId,
    this.finishOrder = const [],
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
            // Table center
            Container(
              width: tableSize,
              height: tableSize,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.3),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF4CAF50), width: 2),
              ),
            ),
            // Opponent seats distributed across the top
            ...List.generate(count, (i) {
              final entry = opponents[i];
              final isFinished = finishOrder.any((f) => f['playerId'] == entry.key);
              final isTurn = entry.key == currentTurnPlayerId;
              final name = entry.key.length > 4 ? entry.key.substring(0, 4) : entry.key;

              // Distribute seats evenly: calculate x position as fraction of width
              final double fraction = count <= 1 ? 0.5 : i / (count - 1);
              final leftPadding = 60.0;
              final availableWidth = constraints.maxWidth - leftPadding * 2;
              final xPos = leftPadding + fraction * availableWidth - 40; // 40 = half seat width

              return Positioned(
                top: 8,
                left: xPos,
                child: _OpponentSeat(
                  name: name,
                  cardCount: isFinished ? 0 : entry.value,
                  isActive: isTurn,
                  isFinished: isFinished,
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

  const _OpponentSeat({
    required this.name,
    required this.cardCount,
    required this.isActive,
    required this.isFinished,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 80,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFD4380D).withOpacity(0.2)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: isActive
            ? Border.all(color: const Color(0xFFD4380D), width: 2)
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: isActive ? const Color(0xFFD4380D) : Colors.grey,
            child: Text(name[0], style: const TextStyle(fontSize: 12)),
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
