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

    return Container(
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          // Table center
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.3),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF4CAF50), width: 2),
              ),
            ),
          ),
          // Position opponent seats
          ..._buildOpponentSeats(opponents, context),
        ],
      ),
    );
  }

  List<Widget> _buildOpponentSeats(
    List<MapEntry<String, int>> opponents,
    BuildContext context,
  ) {
    final widgets = <Widget>[];
    final count = opponents.length;

    for (var i = 0; i < count; i++) {
      final entry = opponents[i];
      final isFinished = finishOrder.any((f) => f['playerId'] == entry.key);
      final isTurn = entry.key == currentTurnPlayerId;

      // Position opponents in a semi-circle at the top
      double topOffset = 10;
      double leftOffset;

      if (count == 1) {
        leftOffset = 100;
      } else if (count == 2) {
        leftOffset = 20 + (i * 160.0);
      } else if (count == 3) {
        leftOffset = 10 + (i * 110.0);
      } else {
        // count == 4
        leftOffset = 5 + (i * 80.0);
      }

      widgets.add(
        Positioned(
          top: topOffset,
          left: leftOffset,
          child: _OpponentSeat(
            name: entry.key.length > 4 ? entry.key.substring(0, 4) : entry.key,
            cardCount: isFinished ? 0 : entry.value,
            isActive: isTurn,
            isFinished: isFinished,
          ),
        ),
      );
    }

    return widgets;
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
