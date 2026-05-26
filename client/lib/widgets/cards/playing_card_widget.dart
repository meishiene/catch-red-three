import 'package:flutter/material.dart';
import '../../engine/types.dart';
import '../../theme/app_theme.dart';

class PlayingCardWidget extends StatelessWidget {
  final GameCard card;
  final bool faceUp;
  final double size;
  final bool isSelected;

  const PlayingCardWidget({
    super.key,
    required this.card,
    this.faceUp = true,
    this.size = 80,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!faceUp) return _buildCardBack();

    return Container(
      width: size * 0.72,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 4,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _rankText,
            style: TextStyle(
              fontSize: size * 0.30,
              fontWeight: FontWeight.bold,
              color: _isRed ? Colors.red.shade700 : Colors.black87,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _suitSymbol,
            style: TextStyle(
              fontSize: size * 0.24,
              color: _isRed ? Colors.red.shade600 : Colors.black87,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      width: size * 0.72,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A5276), Color(0xFF0D3B56)],
        ),
        border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 4,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.45,
          height: size * 0.65,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 1),
          ),
          child: Center(
            child: Text(
              '抓',
              style: TextStyle(
                fontSize: size * 0.25,
                color: AppColors.gold.withOpacity(0.8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _rankText {
    switch (card.rank) {
      case Rank.FIVE: return '5';
      case Rank.SIX: return '6';
      case Rank.SEVEN: return '7';
      case Rank.EIGHT: return '8';
      case Rank.NINE: return '9';
      case Rank.TEN: return '10';
      case Rank.JACK: return 'J';
      case Rank.QUEEN: return 'Q';
      case Rank.KING: return 'K';
      case Rank.ACE: return 'A';
      case Rank.TWO: return '2';
      case Rank.THREE: return '3';
      case Rank.FOUR: return '4';
      case Rank.SMALL_JOKER: return '小';
      case Rank.BIG_JOKER: return '大';
    }
  }

  String get _suitSymbol {
    switch (card.suit) {
      case Suit.S: return '♠';
      case Suit.H: return '♥';
      case Suit.C: return '♣';
      case Suit.D: return '♦';
      case Suit.JOKER: return '王';
    }
  }

  bool get _isRed => card.suit == Suit.H || card.suit == Suit.D;
}
