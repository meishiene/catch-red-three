import 'package:flutter/material.dart';
import '../../engine/types.dart';
import '../cards/playing_card_widget.dart';

class RevealDialog extends StatelessWidget {
  final List<Card> mustReveal;
  final List<Card> canReveal;
  final Function(List<String>) onReveal;
  final VoidCallback onSkip;

  const RevealDialog({
    super.key,
    required this.mustReveal,
    required this.canReveal,
    required this.onReveal,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final selectedIds = <String>{...mustReveal.map((c) => c.id)};

    return StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('亮明身份'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (mustReveal.isNotEmpty) ...[
              const Text('必须亮明:', style: TextStyle(color: Colors.orange)),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: mustReveal.map((c) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: PlayingCardWidget(card: c, size: 60),
                )).toList(),
              ),
              const SizedBox(height: 16),
            ],
            if (canReveal.isNotEmpty) ...[
              const Text('可选择亮明:', style: TextStyle(color: Colors.blue)),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: canReveal.map((c) {
                  final isSelected = selectedIds.contains(c.id);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedIds.remove(c.id);
                        } else {
                          selectedIds.add(c.id);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform: isSelected
                          ? Matrix4.translationValues(0, -8, 0)
                          : Matrix4.identity(),
                      child: PlayingCardWidget(card: c, size: 60),
                    ),
                  );
                }).toList(),
              ),
            ],
            if (mustReveal.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('亮明后该牌牌力将大于4',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: onSkip,
            child: const Text('跳过'),
          ),
          ElevatedButton(
            onPressed: () => onReveal(selectedIds.toList()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4380D),
              foregroundColor: Colors.white,
            ),
            child: const Text('亮明'),
          ),
        ],
      ),
    );
  }
}
