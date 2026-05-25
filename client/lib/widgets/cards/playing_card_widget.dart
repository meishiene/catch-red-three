import 'package:flutter/material.dart';
import '../../engine/types.dart';
import '../../engine/card.dart';

class PlayingCardWidget extends StatelessWidget {
  final Card card;
  final bool faceUp;
  final double size;

  const PlayingCardWidget({
    super.key,
    required this.card,
    this.faceUp = true,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    if (!faceUp) return _buildCardBack();

    return Container(
      width: size * 0.7,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black26),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(1, 1)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _rankText,
            style: TextStyle(
              fontSize: size * 0.28,
              fontWeight: FontWeight.bold,
              color: _isRed ? Colors.red : Colors.black87,
            ),
          ),
          Text(
            _suitText,
            style: TextStyle(
              fontSize: size * 0.22,
              color: _isRed ? Colors.red : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      width: size * 0.7,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF1A5276),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blueGrey),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(1, 1)),
        ],
      ),
      child: const Center(
        child: Text('🀄', style: TextStyle(fontSize: 24)),
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

  String get _suitText {
    switch (card.suit) {
      case Suit.S: return '♠';
      case Suit.H: return '♥';
      case Suit.C: return '♣';
      case Suit.D: return '♦';
      case Suit.JOKER: return '王';
    }
  }

  bool get _isRed {
    return card.suit == Suit.H || card.suit == Suit.D;
  }
}
