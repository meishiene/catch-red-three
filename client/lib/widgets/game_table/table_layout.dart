import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

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
    this.playerNames = const {},
    this.revealedCards = const [],
  });

  @override
  Widget build(BuildContext context) {
    final opponents = opponentCounts.entries.toList();
    if (opponents.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final count = opponents.length;

        return Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.5, 0.7),
              radius: 1.0,
              colors: [
                Color(0xFF2E5A1E),
                AppColors.tableDark,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Table center — decorative ring
              Positioned(
                top: height * 0.28,
                left: width * 0.15,
                child: Container(
                  width: width * 0.7,
                  height: height * 0.35,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF1B5E20).withOpacity(0.5),
                        const Color(0xFF0D3B0F).withOpacity(0.8),
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.gold.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              // Opponent seats in semi-circle
              ...List.generate(count, (i) {
                final entry = opponents[i];
                final playerId = entry.key;
                final isFinished = finishOrder.any((f) => f['playerId'] == playerId);
                final isTurn = playerId == currentTurnPlayerId;
                final name = playerNames[playerId] ?? _defaultName(playerId);
                final team = teams[playerId];
                final hasRevealed = revealedCards.any((r) => r['playerId'] == playerId);

                // Arc from -160 to -20 degrees
                final startAngle = -2.8;
                final endAngle = -0.34;
                final angle = count <= 1
                    ? (startAngle + endAngle) / 2
                    : startAngle + (endAngle - startAngle) * i / (count - 1);

                final radius = width * 0.38;
                final centerX = width / 2;
                final centerY = height * 0.5;
                final x = centerX + radius * cos(angle) - 42;
                final y = centerY + radius * sin(angle) - 15;

                return Positioned(
                  left: x,
                  top: y,
                  child: _PlayerSeat(
                    name: name,
                    cardCount: isFinished ? 0 : entry.value,
                    isActive: isTurn,
                    isFinished: isFinished,
                    team: team,
                    hasRevealed: hasRevealed,
                  ),
                );
              }),
              // Finish order indicator
              if (finishOrder.isNotEmpty)
                Positioned(
                  bottom: 8,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      finishOrder.map((e) => e['position'].toString()).join(' → '),
                      style: const TextStyle(fontSize: 11, color: Colors.white54),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _defaultName(String id) {
    final num = id.replaceAll('p', '');
    final n = int.tryParse(num);
    return n != null && n > 0 ? '电脑$n' : id;
  }
}

class _PlayerSeat extends StatelessWidget {
  final String name;
  final int cardCount;
  final bool isActive;
  final bool isFinished;
  final String? team;
  final bool hasRevealed;

  const _PlayerSeat({
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
    final borderColor = isActive
        ? AppColors.gold
        : isRed
            ? AppColors.redTeam.withOpacity(0.6)
            : Colors.white24;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 84,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.gold.withOpacity(0.1)
            : Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: isActive ? 2 : 1),
        boxShadow: isActive
            ? [BoxShadow(color: AppColors.gold.withOpacity(0.3), blurRadius: 8)]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isActive
                  ? const LinearGradient(colors: [AppColors.gold, AppColors.goldDark])
                  : isRed
                      ? const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFB71C1C)])
                      : const LinearGradient(colors: [Color(0xFF616161), Color(0xFF424242)]),
              boxShadow: isActive
                  ? [BoxShadow(color: AppColors.gold.withOpacity(0.4), blurRadius: 6)]
                  : null,
            ),
            child: Center(
              child: Text(
                isRed ? '红' : name[0],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Name
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? AppColors.gold : Colors.white70,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // Status
          if (isFinished)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.check_circle, color: Colors.green, size: 12),
                SizedBox(width: 2),
                Text('完成', style: TextStyle(fontSize: 10, color: Colors.green)),
              ],
            )
          else ...[
            if (hasRevealed)
              const Text('已亮', style: TextStyle(fontSize: 10, color: Colors.orange)),
            Text(
              '${cardCount}张',
              style: TextStyle(
                fontSize: 11,
                color: isActive ? AppColors.gold : Colors.white54,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
