import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_provider.dart';
import '../providers/local_game_provider.dart';
import '../providers/game_provider.dart';

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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isDraw ? Icons.handshake : Icons.emoji_events,
                size: 80,
                color: isDraw ? Colors.grey : isRedWin ? const Color(0xFFD4380D) : Colors.amber,
              ),
              const SizedBox(height: 24),
              Text(
                isDraw ? '平局!' : '游戏结束',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                isDraw ? '双方都有人被抓住' : isRedWin ? '红方胜利!' : '黑方胜利!',
                style: TextStyle(
                  fontSize: 20,
                  color: isRedWin ? const Color(0xFFD4380D) : Colors.amber,
                ),
              ),
              if (caughtPlayerId != null) ...[
                const SizedBox(height: 8),
                Text(
                  '被抓: $caughtPlayerId',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
              const SizedBox(height: 32),
              if (finishOrder.isNotEmpty) ...[
                const Text('完成顺序', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...finishOrder.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${entry['position']}. ',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      Text(
                        entry['playerId'] as String,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                )),
              ],
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(localGameProvider.notifier).clear();
                    Navigator.pushReplacementNamed(context, '/');
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('返回主页'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4380D),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (isSingle)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref.read(localGameProvider.notifier).startNewRound();
                      Navigator.pushReplacementNamed(context, '/game');
                    },
                    icon: const Icon(Icons.replay),
                    label: const Text('再来一局'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
