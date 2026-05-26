import 'package:flutter/material.dart';
import '../../engine/types.dart';
import '../cards/playing_card_widget.dart';

class TributeDialog extends StatefulWidget {
  final Map<String, dynamic> tributeData;
  final VoidCallback onContinue;
  final Function(String) onReturnCard;

  const TributeDialog({
    super.key,
    required this.tributeData,
    required this.onContinue,
    required this.onReturnCard,
  });

  @override
  State<TributeDialog> createState() => _TributeDialogState();
}

class _TributeDialogState extends State<TributeDialog> {
  String? _selectedCardId;

  bool get _needsReturn => widget.tributeData.containsKey('receivedCard');

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_needsReturn ? '回赠一张牌' : '进贡'),
      content: _needsReturn ? _buildReturnContent() : _buildGiveContent(),
      actions: _buildActions(),
    );
  }

  Widget _buildGiveContent() {
    final card = widget.tributeData['card'] as GameCard;
    final toName = widget.tributeData['toPlayerName'] as String? ?? '';
    final fromId = widget.tributeData['fromPlayerId'] as String? ?? '';
    final isHumanGiving = fromId == 'p0';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isHumanGiving ? '你向 $toName 进贡:' : '$fromId 向你进贡:',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        PlayingCardWidget(card: card, size: 80),
        const SizedBox(height: 16),
        Text(
          isHumanGiving ? '系统自动选择了你最大的牌' : '对方将在下一步回赠一张牌',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildReturnContent() {
    final receivedCard = widget.tributeData['receivedCard'] as GameCard;
    final fromName = widget.tributeData['fromPlayerName'] as String? ?? '';
    final hand = widget.tributeData['hand'] as List<GameCard>? ?? [];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$fromName 向你进贡了:', style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        PlayingCardWidget(card: receivedCard, size: 70),
        const SizedBox(height: 16),
        const Text('请选择一张牌回赠:', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: hand.map((card) {
                final isSelected = _selectedCardId == card.id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCardId = card.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    transform: isSelected
                        ? Matrix4.translationValues(0, -10, 0)
                        : Matrix4.identity(),
                    child: PlayingCardWidget(card: card, size: 80),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActions() {
    if (_needsReturn) {
      return [
        TextButton(
          onPressed: _selectedCardId != null
              ? () => widget.onReturnCard(_selectedCardId!)
              : null,
          child: const Text('回赠'),
        ),
      ];
    }
    return [
      ElevatedButton(
        onPressed: widget.onContinue,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD4380D),
          foregroundColor: Colors.white,
        ),
        child: const Text('继续'),
      ),
    ];
  }
}
