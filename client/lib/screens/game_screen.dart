import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_provider.dart';
import '../providers/game_provider.dart';
import '../providers/local_game_provider.dart';
import '../models/game_state.dart';
import '../engine/types.dart';
import '../engine/card.dart';
import '../widgets/cards/playing_card_widget.dart';
import '../widgets/game_table/table_layout.dart';
import '../widgets/actions/reveal_dialog.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  @override
  void initState() {
    super.initState();
    _checkGameStart();
  }

  void _checkGameStart() {
    final isSingle = ref.read(isSinglePlayerProvider);
    if (isSingle) {
      final difficulty = ref.read(aiDifficultyProvider);
      final playerCount = 3; // TODO: pass from setup screen
      final nickname = ref.read(nicknameProvider);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(localGameProvider.notifier).startNewGame(
          3,
          AIDifficulty.NORMAL, // TODO: from setup
          nickname,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSingle = ref.watch(isSinglePlayerProvider);

    if (isSingle) {
      return _buildGameContent(context, ref.watch(localGameProvider), isSingle: true);
    } else {
      final roomCode = ref.watch(roomCodeProvider);
      return _buildGameContent(context, ref.watch(gameProvider),
          isSingle: false, roomCode: roomCode);
    }
  }

  Widget _buildGameContent(BuildContext context, GameState gameState, {
    bool isSingle = false,
    String? roomCode,
  }) {
    // Identity reveal dialog
    if (gameState.phase == 'IDENTITY_REVEAL') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showRevealDialog(context, isSingle);
      });
    }

    // Game over
    if (gameState.phase == 'GAME_OVER') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/game-result');
      });
    }

    final notifier = isSingle
        ? ref.read(localGameProvider.notifier)
        : ref.read(gameProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(isSingle ? '人机对战' : '房间: ${roomCode ?? ""}'),
        actions: [
          if (gameState.phase == 'PLAYING')
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '手牌: ${gameState.hand.length}张',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: TableLayout(
              opponentCounts: gameState.opponentCardCounts,
              currentTurnPlayerId: gameState.currentTurnPlayerId,
              finishOrder: gameState.finishOrder,
            ),
          ),
          if (gameState.board != null)
            _buildCenterPlayArea(gameState.board!),
          Expanded(
            flex: 4,
            child: _buildMyHand(gameState, notifier),
          ),
          if (gameState.currentTurnPlayerId != null)
            _buildActionButtons(gameState, notifier),
        ],
      ),
    );
  }

  void _showRevealDialog(BuildContext context, bool isSingle) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RevealDialog(
        mustReveal: const [],
        canReveal: const [],
        onReveal: (cardIds) {
          Navigator.pop(ctx);
          if (isSingle) {
            ref.read(localGameProvider.notifier).reveal(cardIds);
          } else {
            ref.read(gameProvider.notifier).reveal(cardIds);
          }
        },
        onSkip: () {
          Navigator.pop(ctx);
          if (isSingle) {
            ref.read(localGameProvider.notifier).skipReveal();
          } else {
            ref.read(gameProvider.notifier).skipReveal();
          }
        },
      ),
    );
  }

  Widget _buildCenterPlayArea(BoardState board) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _playTypeLabel(board.playType),
            style: const TextStyle(color: Colors.orange, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: board.cards.map((c) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: PlayingCardWidget(card: c, faceUp: true, size: 60),
            )).toList(),
          ),
          Text(
            board.playedByPlayerId,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _playTypeLabel(PlayType type) {
    switch (type) {
      case PlayType.SINGLE: return '单张';
      case PlayType.PAIR: return '对子';
      case PlayType.BOMB: return '炸弹!';
      case PlayType.BIG_BOMB: return '大炸弹!!';
      case PlayType.JOKER_BOMB: return '王炸!!!';
    }
  }

  Widget _buildMyHand(GameState state, dynamic notifier) {
    if (state.hand.isEmpty) {
      return const Center(child: Text('等待发牌...', style: TextStyle(color: Colors.grey)));
    }

    return Column(
      children: [
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: state.hand.map((card) {
                final isSelected = state.selectedCardIds.contains(card.id);
                return GestureDetector(
                  onTap: () {
                    if (state.currentTurnPlayerId != null) {
                      notifier.toggleCardSelection(card.id);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    transform: isSelected
                        ? Matrix4.translationValues(0, -16, 0)
                        : Matrix4.identity(),
                    child: PlayingCardWidget(card: card, faceUp: true, size: 80),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(GameState state, dynamic notifier) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!state.isFirstTrick || state.board != null)
            SizedBox(
              width: 120,
              height: 48,
              child: OutlinedButton(
                onPressed: () => notifier.pass(),
                child: const Text('过牌'),
              ),
            ),
          const SizedBox(width: 24),
          SizedBox(
            width: 120,
            height: 48,
            child: ElevatedButton(
              onPressed: state.selectedCardIds.isNotEmpty
                  ? () => notifier.playSelectedCards()
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4380D),
              ),
              child: Text('出牌 (${state.selectedCardIds.length})'),
            ),
          ),
        ],
      ),
    );
  }
}
