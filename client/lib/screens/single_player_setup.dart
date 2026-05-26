import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

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
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: const Text('人机对战',
                    style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
                const Spacer(flex: 2),
                // Player count
                _buildSection('游戏人数', [
                  for (final n in [3, 4, 5])
                    _ChoiceCard(
                      label: '$n人',
                      selected: _playerCount == n,
                      onTap: () => setState(() => _playerCount = n),
                    ),
                ]),
                const SizedBox(height: 32),
                // Difficulty
                _buildSection('AI 难度', [
                  for (final e in _difficultyLabels.entries)
                    _ChoiceCard(
                      label: e.value,
                      selected: _difficulty == e.key,
                      onTap: () => setState(() => _difficulty = e.key),
                    ),
                ]),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.read(isSinglePlayerProvider.notifier).state = true;
                      ref.read(aiDifficultyProvider.notifier).state = _difficulty;
                      ref.read(playerCountProvider.notifier).state = _playerCount;
                      Navigator.pushReplacementNamed(context, '/game');
                    },
                    icon: const Icon(Icons.play_arrow, size: 24),
                    label: const Text('开始游戏', style: TextStyle(fontSize: 17)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 17, color: Colors.white70)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 80,
          height: 44,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.gold.withOpacity(0.2)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.gold : Colors.white.withOpacity(0.1),
              width: selected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? AppColors.gold : Colors.white54,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
