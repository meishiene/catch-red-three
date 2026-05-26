import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_provider.dart';
import '../providers/game_provider.dart';
import '../providers/local_game_provider.dart';
import '../models/game_state.dart';
import '../engine/types.dart';
import '../ai/ai_scorer.dart';
import '../theme/app_theme.dart';
import '../widgets/cards/playing_card_widget.dart';
import '../widgets/game_table/table_layout.dart';
import '../widgets/actions/reveal_dialog.dart';
import '../widgets/actions/tribute_dialog.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  bool _revealDialogShown = false;
  Map<String, dynamic>? _lastTributeData;

  @override
  void initState() {
    super.initState();
    _checkGameStart();
  }

  void _checkGameStart() {
    final isSingle = ref.read(isSinglePlayerProvider);
    if (isSingle) {
      final currentPhase = ref.read(localGameProvider).phase;
      if (currentPhase != 'WAITING' && currentPhase != 'GAME_OVER') return;
      final difficultyStr = ref.read(aiDifficultyProvider);
      final difficulty = AIDifficulty.values.firstWhere(
        (d) => d.name == difficultyStr,
        orElse: () => AIDifficulty.NORMAL,
      );
      final playerCount = ref.read(playerCountProvider);
      final nickname = ref.read(nicknameProvider);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(localGameProvider.notifier).startNewGame(
          playerCount,
          difficulty,
          nickname,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSingle = ref.watch(isSinglePlayerProvider);
    final gameState = isSingle ? ref.watch(localGameProvider) : ref.watch(gameProvider);

    if (gameState.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(gameState.errorMessage!),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
          if (isSingle) {
            ref.read(localGameProvider.notifier).clearError();
          } else {
            ref.read(gameProvider.notifier).clearError();
          }
        }
      });
    }

    if (isSingle) {
      return _buildGameContent(context, gameState, isSingle: true);
    } else {
      final roomCode = ref.watch(roomCodeProvider);
      return _buildGameContent(context, gameState,
          isSingle: false, roomCode: roomCode);
    }
  }

  Widget _buildGameContent(BuildContext context, GameState state, {
    bool isSingle = false,
    String? roomCode,
  }) {
    _checkDialogs(context, state, isSingle);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(state, isSingle, roomCode),
      body: Container(
        decoration: AppTheme.tableDecoration,
        child: SafeArea(
          child: Column(
            children: [
              // Opponent area
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.22,
                child: TableLayout(
                  opponentCounts: state.opponentCardCounts,
                  currentTurnPlayerId: state.currentTurnPlayerId,
                  finishOrder: state.finishOrder,
                  teams: state.teams,
                  playerNames: _buildPlayerNames(state),
                  revealedCards: state.revealedCards,
                ),
              ),
              // Center: board cards or phase info
              _buildCenterInfo(state),
              const Spacer(),
              // Hand area
              _buildHandArea(state, isSingle),
              const SizedBox(height: 8),
              // Action buttons
              if (state.currentTurnPlayerId != null && state.phase == 'PLAYING')
                _buildActionBar(state, isSingle),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(GameState state, bool isSingle, String? roomCode) {
    return AppBar(
      title: Text(isSingle ? '人机对战' : '房间: ${roomCode ?? ""}'),
      actions: [
        if (state.myTeam != null)
          _TeamChip(team: state.myTeam!),
        if (state.phase == 'PLAYING')
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              label: Text('${state.hand.length}张',
                style: const TextStyle(color: Colors.white, fontSize: 13)),
              backgroundColor: Colors.black38,
              side: BorderSide.none,
            ),
          ),
      ],
    );
  }

  void _checkDialogs(BuildContext context, GameState state, bool isSingle) {
    // Identity reveal
    if (state.phase == 'IDENTITY_REVEAL' && !_revealDialogShown) {
      _revealDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showRevealDialog(context, isSingle, state);
      });
    }
    if (state.phase != 'IDENTITY_REVEAL') {
      _revealDialogShown = false;
    }

    // Tribute
    if (state.phase == 'TRIBUTE' &&
        state.tributeData != null &&
        state.tributeData != _lastTributeData) {
      final data = state.tributeData;
      _lastTributeData = data;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTributeDialog(context, isSingle, state);
      });
    }
    if (state.tributeData == null) {
      _lastTributeData = null;
    }

    // Game over
    if (state.phase == 'GAME_OVER') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/game-result');
      });
    }
  }

  Widget _buildCenterInfo(GameState state) {
    if (state.board != null) {
      return _buildBoardCards(state.board!);
    }
    if (state.phase == 'DEALT' || state.phase == 'WAITING') {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('发牌中...', style: TextStyle(color: Colors.white54, fontSize: 16)),
      );
    }
    if (state.phase == 'TRIBUTE') {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('进贡阶段...', style: TextStyle(color: AppColors.gold, fontSize: 16)),
      );
    }
    return const SizedBox(height: 8);
  }

  Widget _buildBoardCards(BoardState board) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _playTypeLabel(board.playType),
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: board.cards.map((c) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: PlayingCardWidget(card: c, size: 72),
            )).toList(),
          ),
          const SizedBox(height: 4),
          Text(
            board.playedByPlayerId,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
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

  Widget _buildHandArea(GameState state, bool isSingle) {
    if (state.hand.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('等待发牌...', style: TextStyle(color: Colors.white38)),
      );
    }

    final sorted = List<GameCard>.from(state.hand);

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: sorted.length,
        itemBuilder: (_, i) {
          final card = sorted[i];
          final sel = state.selectedCardIds.contains(card.id);
          final canPlay = state.currentTurnPlayerId != null;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: GestureDetector(
              onTap: canPlay
                  ? () {
                      if (isSingle) {
                        ref.read(localGameProvider.notifier).toggleCardSelection(card.id);
                      } else {
                        ref.read(gameProvider.notifier).toggleCardSelection(card.id);
                      }
                    }
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutBack,
                transform: sel
                    ? (Matrix4.identity()..translate(0.0, -18.0))
                    : Matrix4.identity(),
                child: PlayingCardWidget(
                  card: card,
                  size: 96,
                  isSelected: sel,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionBar(GameState state, bool isSingle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          if (!state.isFirstTrick || state.board != null)
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    if (isSingle) {
                      ref.read(localGameProvider.notifier).pass();
                    } else {
                      ref.read(gameProvider.notifier).pass();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('过牌', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          if (!state.isFirstTrick || state.board != null)
            const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: state.selectedCardIds.isNotEmpty
                    ? () {
                        if (isSingle) {
                          ref.read(localGameProvider.notifier).playSelectedCards();
                        } else {
                          ref.read(gameProvider.notifier).playSelectedCards();
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white12,
                  disabledForegroundColor: Colors.white30,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: state.selectedCardIds.isNotEmpty ? 4 : 0,
                  shadowColor: AppColors.primaryRed.withOpacity(0.4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('出牌', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    if (state.selectedCardIds.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${state.selectedCardIds.length}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRevealDialog(BuildContext context, bool isSingle, GameState state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RevealDialog(
        mustReveal: state.mustRevealCards,
        canReveal: state.canRevealCards,
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

  void _showTributeDialog(BuildContext context, bool isSingle, GameState state) {
    if (!isSingle || state.tributeData == null) return;
    final data = state.tributeData!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => TributeDialog(
        tributeData: data,
        onContinue: () {
          Navigator.pop(ctx);
          ref.read(localGameProvider.notifier).tributeContinue();
        },
        onReturnCard: (cardId) {
          Navigator.pop(ctx);
          ref.read(localGameProvider.notifier).tributeReturn(cardId);
        },
      ),
    );
  }

  Map<String, String> _buildPlayerNames(GameState state) {
    final names = <String, String>{};
    for (final id in state.opponentCardCounts.keys) {
      final num = id.replaceAll('p', '');
      final n = int.tryParse(num);
      names[id] = n != null && n > 0 ? '电脑$n' : id;
    }
    return names;
  }
}

class _TeamChip extends StatelessWidget {
  final String team;
  const _TeamChip({required this.team});

  @override
  Widget build(BuildContext context) {
    final isRed = team == 'red';
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isRed
              ? AppColors.redTeam.withOpacity(0.25)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRed ? AppColors.redTeam : Colors.white30,
            width: 1,
          ),
        ),
        child: Text(
          isRed ? '红队' : '黑队',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isRed ? AppColors.redTeam : Colors.white70,
          ),
        ),
      ),
    );
  }
}
