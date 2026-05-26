import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_provider.dart';
import '../providers/local_game_provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

class GameResultScreen extends ConsumerWidget {
  const GameResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSingle = ref.read(isSinglePlayerProvider);
    final gameState = isSingle
        ? ref.read(localGameProvider)
        : ref.read(gameProvider);
    final data = gameState.gameOverData ?? {};

    final winner = data['winner'] as String? ?? 'draw';
    final finishOrder = (data['finishOrder'] as List?)
        ?.map((e) => Map<String, dynamic>.from(e))
        .toList() ?? [];
    final caughtPlayerId = data['caughtPlayerId'] as String?;

    final isRedWin = winner == 'red';
    final isDraw = winner == 'draw';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A3A1A), AppColors.tableDark],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: isDraw
                          ? [Colors.grey.shade400, Colors.grey.shade700]
                          : isRedWin
                              ? [AppColors.redTeam, const Color(0xFFB71C1C)]
                              : [AppColors.gold, AppColors.goldDark],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isDraw
                                ? Colors.grey
                                : isRedWin
                                    ? AppColors.redTeam
                                    : AppColors.gold)
                            .withOpacity(0.3),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Icon(
                    isDraw ? Icons.handshake : Icons.emoji_events,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isDraw ? '平局!' : '游戏结束',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isDraw ? '双方都有人被抓住' : isRedWin ? '红方胜利!' : '黑方胜利!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDraw
                        ? Colors.grey
                        : isRedWin
                            ? AppColors.redTeam
                            : AppColors.gold,
                  ),
                ),
                if (caughtPlayerId != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '被抓: $caughtPlayerId',
                    style: const TextStyle(fontSize: 14, color: Colors.white38),
                  ),
                ],
                const SizedBox(height: 36),
                if (finishOrder.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.panelDecoration,
                    child: Column(
                      children: [
                        const Text('完成顺序',
                          style: TextStyle(fontSize: 15, color: Colors.white54)),
                        const SizedBox(height: 12),
                        ...finishOrder.map((entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${entry['position']}. ',
                                style: const TextStyle(fontSize: 16, color: AppColors.gold),
                              ),
                              Text(
                                entry['playerId'] as String,
                                style: const TextStyle(fontSize: 16, color: Colors.white70),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.read(localGameProvider.notifier).clear();
                      Navigator.pushReplacementNamed(context, '/');
                    },
                    icon: const Icon(Icons.home, size: 22),
                    label: const Text('返回主页', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (isSingle)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ref.read(localGameProvider.notifier).startNewRound();
                        Navigator.pushReplacementNamed(context, '/game');
                      },
                      icon: const Icon(Icons.replay, size: 22),
                      label: const Text('再来一局', style: TextStyle(fontSize: 16)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(color: Colors.white.withOpacity(0.15)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
