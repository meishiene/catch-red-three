import 'dart:async';
import 'dart:math';
import 'types.dart';
import 'card.dart';
import 'deck.dart';
import 'play_validator.dart';
import 'team_assigner.dart';
import 'win_detector.dart';
import 'tribute.dart';
import 'trick_manager.dart';
import '../ai/ai_engine.dart';
import '../ai/ai_scorer.dart';

typedef GameEventCallback = void Function(String event, Map<String, dynamic> data);

class LocalGameEngine {
  final int maxPlayers;
  final AIDifficulty difficulty;
  final GameEventCallback onEvent;
  final Random _rng = Random();

  String phase = 'WAITING';
  late List<String> playerOrder;
  late Map<String, List<GameCard>> hands;
  late Map<String, String> teams;
  final List<Map<String, dynamic>> revealedCards = [];
  final List<String> finishOrder = [];
  final List<Map<String, dynamic>> players = [];
  late TrickStateData trickState;
  bool isFirstRound = true;
  GameResult? lastGameResult;
  int firstDealtIndex = 0;

  LocalGameEngine({
    required this.maxPlayers,
    this.difficulty = AIDifficulty.NORMAL,
    required this.onEvent,
  });

  void start() {
    phase = 'DEALING';
    onEvent('game:starting', {'countdown': 3});

    Future.delayed(const Duration(seconds: 3), () {
      _dealAndStart();
    });
  }

  void _dealAndStart() {
    int dealerIndex = firstDealtIndex;
    if (!isFirstRound && lastGameResult != null) {
      final idx = playerOrder.indexOf(lastGameResult!.firstFinisherId);
      dealerIndex = idx >= 0 ? idx : _rng.nextInt(maxPlayers);
    } else {
      dealerIndex = _rng.nextInt(maxPlayers);
    }
    firstDealtIndex = dealerIndex;

    // Initialize players if first round
    if (isFirstRound) {
      playerOrder = List.generate(maxPlayers, (i) => 'p$i');
      // p0 = human player
      players.add({'id': 'p0', 'name': '你', 'isAI': false});
      for (var i = 1; i < maxPlayers; i++) {
        players.add({'id': 'p$i', 'name': '电脑$i', 'isAI': true});
      }
    }

    final dealtHands = deal(maxPlayers, dealerIndex);
    hands = {};
    teams = {};
    revealedCards.clear();
    finishOrder.clear();

    for (var i = 0; i < playerOrder.length; i++) {
      hands[playerOrder[i]] = dealtHands[i];
    }

    teams = assignTeams(hands);

    // Send hand to human player
    final humanHand = hands['p0'] ?? [];
    onEvent('game:dealt', {
      'hand': humanHand,
      'totalPlayers': maxPlayers,
    });

    // Determine opponent card counts
    final opponentCounts = <String, int>{};
    for (var i = 1; i < maxPlayers; i++) {
      opponentCounts['p$i'] = hands['p$i']?.length ?? 0;
    }

    // Tribute phase for non-first rounds
    if (!isFirstRound && lastGameResult != null && lastGameResult!.winner != 'draw') {
      phase = 'TRIBUTE';
      _executeTribute();
    } else {
      phase = 'IDENTITY_REVEAL';
      _startIdentityPhase();
    }
  }

  void _executeTribute() {
    final pairs = determineTributePairs(lastGameResult!, teams, hands, maxPlayers);

    for (final pair in pairs) {
      final card = applyTributeGive(hands, pair);
      if (card != null) {
        final winnerHand = hands[pair.toPlayerId] ?? [];
        GameCard returnCard;
        if (pair.toPlayerId == 'p0') {
          // Human chooses (handled via UI)
          returnCard = winnerHand.first;
        } else {
          returnCard = chooseTributeReturnCard(winnerHand, AIDifficulty.NORMAL);
        }
        applyTributeReceive(hands, pair, returnCard);
      }
    }

    onEvent('game:tribute-complete', {});
    phase = 'IDENTITY_REVEAL';
    _startIdentityPhase();
  }

  void _startIdentityPhase() {
    // Process AI reveals automatically
    for (var i = 1; i < maxPlayers; i++) {
      final aiId = 'p$i';
      final hand = hands[aiId] ?? [];
      final eligibility = getRevealEligibility(hand, maxPlayers);
      final toReveal = shouldRevealIdentity(
        eligibility['canReveal']!,
        eligibility['mustReveal']!,
        difficulty,
      );
      if (toReveal.isNotEmpty) {
        applyReveal(hand, toReveal);
        for (final cardId in toReveal) {
          revealedCards.add({'playerId': aiId, 'cardId': cardId});
        }
      }
    }

    // Prompt human player
    final humanHand = hands['p0'] ?? [];
    final eligibility = getRevealEligibility(humanHand, maxPlayers);

    onEvent('game:identity-phase', {
      'mustReveal': eligibility['mustReveal']!,
      'canReveal': eligibility['canReveal']!,
    });

    // If nothing to reveal, auto-continue
    if (eligibility['mustReveal']!.isEmpty && eligibility['canReveal']!.isEmpty) {
      _finishIdentityPhase();
    }
  }

  void handleReveal(List<String> cardIds) {
    final hand = hands['p0'] ?? [];
    applyReveal(hand, cardIds);
    for (final cardId in cardIds) {
      revealedCards.add({'playerId': 'p0', 'cardId': cardId});
    }
    _finishIdentityPhase();
  }

  void handleSkipReveal() {
    _finishIdentityPhase();
  }

  void _finishIdentityPhase() {
    phase = 'PLAYING';
    _startPlaying();
  }

  void _startPlaying() {
    final redFiveHolder = findRedFiveHolder(hands);
    final firstLeader = redFiveHolder ?? playerOrder[isFirstRound ? 0 : (firstDealtIndex % maxPlayers)];

    final activeOrder = playerOrder.where((id) => !finishOrder.contains(id)).toList();
    trickState = createTrickState(activeOrder, firstLeader, isFirstRound);

    onEvent('game:trick-start', {
      'leaderPlayerId': firstLeader,
      'isFirstTrick': isFirstRound,
    });

    _requestTurn(firstLeader);
  }

  void _requestTurn(String playerId) {
    final hand = hands[playerId] ?? [];
    final board = getBoardState(trickState);
    final isLeader = isTrickLeader(trickState, playerId);
    final player = players.firstWhere((p) => p['id'] == playerId);
    final isAI = player['isAI'] as bool;

    if (playerId == 'p0') {
      // Human turn
      onEvent('game:turn-request', {
        'board': board != null ? {
          'cards': board.cards,
          'playType': board.playType.name,
          'playedByPlayerId': board.playedByPlayerId,
        } : null,
        'isFirstTrick': trickState.isFirstTrick,
        'isTrickLeader': isLeader,
      });
    } else if (isAI) {
      // AI turn with delay for natural feel
      Future.delayed(Duration(milliseconds: 800 + _rng.nextInt(1500)), () {
        if (phase != 'PLAYING') return;
        if (getCurrentPlayerId(trickState) != playerId) return;
        _handleAITurn(playerId);
      });
    }
  }

  void _handleAITurn(String playerId) {
    final hand = hands[playerId] ?? [];
    final board = getBoardState(trickState);
    final team = teams[playerId] ?? 'black';
    final teamMembers = getTeamMembers(teams, team);
    final teamCardCounts = teamMembers
        .where((id) => id != playerId)
        .map((id) => hands[id]?.length ?? 0)
        .toList();

    final isLeader = isTrickLeader(trickState, playerId);

    if (isFirstRound && isLeader) {
      final fives = aiSelectOpeningPlay(hand, difficulty);
      if (fives.isNotEmpty) {
        _applyPlay(playerId, fives);
        return;
      }
    }

    final decision = decideAI(hand, board, difficulty, isLeader, teamCardCounts);

    if (decision.action == 'pass') {
      _applyPass(playerId);
    } else if (decision.cards != null) {
      _applyPlay(playerId, decision.cards!);
    }
  }

  void handleHumanPlay(List<String> cardIds) {
    if (phase != 'PLAYING') return;
    if (getCurrentPlayerId(trickState) != 'p0') return;

    final hand = hands['p0'] ?? [];
    final selectedCards = cardIds
        .map((id) => hand.firstWhere((c) => c.id == id))
        .toList();

    if (selectedCards.length != cardIds.length) return;

    final board = getBoardState(trickState);
    final isLeader = isTrickLeader(trickState, 'p0');

    final validation = validatePlay(selectedCards, hand, board, trickState.isFirstTrick, isLeader);
    if (!validation.valid) {
      onEvent('game:error', {'message': validation.error ?? '出牌无效'});
      return;
    }

    _applyPlay('p0', selectedCards);
  }

  void handleHumanPass() {
    if (phase != 'PLAYING') return;
    if (getCurrentPlayerId(trickState) != 'p0') return;

    final board = getBoardState(trickState);
    if (isTrickLeader(trickState, 'p0') && board == null) return;

    _applyPass('p0');
  }

  void _applyPlay(String playerId, List<GameCard> cards) {
    final hand = hands[playerId] ?? [];
    final playInfo = determinePlay(cards);
    if (playInfo == null) return;

    // Remove cards from hand
    for (final card in cards) {
      hand.removeWhere((c) => c.id == card.id);
    }

    processPlay(trickState, playerId, cards, playInfo);

    onEvent('game:cards-played', {
      'playerId': playerId,
      'cards': cards,
      'playType': playInfo.type.name,
    });

    // Update opponent counts for human
    final opponentCounts = <String, int>{};
    for (var i = 1; i < maxPlayers; i++) {
      opponentCounts['p$i'] = hands['p$i']?.length ?? 0;
    }
    onEvent('game:cards-remaining', {'counts': opponentCounts});

    // Check finish
    if (hand.isEmpty) {
      finishOrder.add(playerId);
      removePlayerFromTrick(trickState, playerId);
      onEvent('game:player-finished', {
        'playerId': playerId,
        'position': finishOrder.length,
      });
    }

    // Check game over
    final unfinished = playerOrder.where((id) => !finishOrder.contains(id)).toList();
    if (unfinished.length <= 1) {
      if (unfinished.length == 1) finishOrder.add(unfinished.first);
      _endGame();
      return;
    }

    _nextTurn();
  }

  void _applyPass(String playerId) {
    final result = processPass(trickState, playerId);
    onEvent('game:player-passed', {'playerId': playerId});

    if (result.startsWith('TRICK_WON:')) {
      final winnerId = result.split(':')[1];
      onEvent('game:trick-won', {'playerId': winnerId});

      if (!finishOrder.contains(winnerId)) {
        resetTrick(trickState, winnerId);
        trickState.activePlayerIds = Set<String>.from(
          trickState.playerOrder.where((id) => !finishOrder.contains(id)),
        );
        trickState.isFirstTrick = false;

        onEvent('game:trick-start', {
          'leaderPlayerId': winnerId,
          'isFirstTrick': false,
        });
        _requestTurn(winnerId);
      }
    } else {
      _nextTurn();
    }
  }

  void _nextTurn() {
    final currentId = getCurrentPlayerId(trickState);
    if (trickState.activePlayerIds.length <= 1) {
      final winnerId = trickState.boardPlayerId;
      if (winnerId != null && !finishOrder.contains(winnerId)) {
        onEvent('game:trick-won', {'playerId': winnerId});
        resetTrick(trickState, winnerId);
        trickState.activePlayerIds = Set<String>.from(
          trickState.playerOrder.where((id) => !finishOrder.contains(id)),
        );
        trickState.isFirstTrick = false;
        onEvent('game:trick-start', {
          'leaderPlayerId': winnerId,
          'isFirstTrick': false,
        });
        _requestTurn(winnerId);
        return;
      }
    }
    _requestTurn(currentId);
  }

  void _endGame() {
    phase = 'GAME_OVER';
    final result = determineWinner(finishOrder, teams);
    lastGameResult = result;
    isFirstRound = false;
    firstDealtIndex = playerOrder.indexOf(finishOrder.first);

    onEvent('game:over', {
      'winner': result.winner,
      'finishOrder': result.finishOrder,
      'redTeam': result.redTeam,
      'blackTeam': result.blackTeam,
      'firstFinisherId': result.firstFinisherId,
      'caughtPlayerId': result.caughtPlayerId,
    });
  }

  void startNewRound() {
    _dealAndStart();
  }

  // Get current state for UI
  Map<String, dynamic> getSnapshot() {
    final hand = hands['p0'] ?? [];
    final board = getBoardState(trickState);
    final opponentCounts = <String, int>{};
    for (var i = 1; i < maxPlayers; i++) {
      opponentCounts['p$i'] = hands['p$i']?.length ?? 0;
    }

    return {
      'phase': phase,
      'hand': hand,
      'board': board,
      'teams': teams,
      'revealedCards': revealedCards,
      'finishOrder': finishOrder.asMap().entries.map((e) => {
        'playerId': e.value,
        'position': e.key + 1,
      }).toList(),
      'opponentCardCounts': opponentCounts,
      'currentTurnPlayerId': phase == 'PLAYING' ? getCurrentPlayerId(trickState) : null,
      'trickLeaderId': trickState.boardPlayerId,
      'isFirstTrick': trickState.isFirstTrick,
    };
  }
}
