import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_provider.dart';

class SinglePlayerSetup extends ConsumerStatefulWidget {
  const SinglePlayerSetup({super.key});

  @override
  ConsumerState<SinglePlayerSetup> createState() => _SinglePlayerSetupState();
}

class _SinglePlayerSetupState extends ConsumerState<SinglePlayerSetup> {
  int _playerCount = 3;
  String _difficulty = 'NORMAL';

  static const _difficultyLabels = {
    'EASY': '简单',
    'NORMAL': '普通',
    'HARD': '困难',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('人机对战')),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('游戏人数', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [3, 4, 5].map((n) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ChoiceChip(
                  label: Text('$n人'),
                  selected: _playerCount == n,
                  onSelected: (_) => setState(() => _playerCount = n),
                ),
              )).toList(),
            ),
            const SizedBox(height: 32),
            const Text('AI 难度', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _difficultyLabels.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ChoiceChip(
                  label: Text(e.value),
                  selected: _difficulty == e.key,
                  onSelected: (_) => setState(() => _difficulty = e.key),
                ),
              )).toList(),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(isSinglePlayerProvider.notifier).state = true;
                  ref.read(aiDifficultyProvider.notifier).state = _difficulty;
                  Navigator.pushReplacementNamed(context, '/game');
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('开始游戏'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4380D),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
