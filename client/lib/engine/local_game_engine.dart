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
  List<TributePair> _pendingTributePairs = [];
  int _currentTributeIndex = 0;
  bool _waitingForHumanTribute = false;

  // Wind (送风) state
  bool _windPending = false;
  String? _windRequesterId;
  String? _windFinisherId;
  BoardState? _windBoard;
  bool _freePlayMode = false;

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
    final opponentCounts = <String, int>{};
    for (var i = 1; i < maxPlayers; i++) {
      opponentCounts['p$i'] = hands['p$i']?.length ?? 0;
    }
    final playerNames = <String, String>{};
    for (final p in players) {
      playerNames[p['id'] as String] = p['name'] as String;
    }
    onEvent('game:dealt', {
      'hand': humanHand,
      'totalPlayers': maxPlayers,
      'teams': teams,
      'opponentCounts': opponentCounts,
      'myTeam': teams['p0'] ?? 'black',
      'playerNames': playerNames,
    });

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
    _pendingTributePairs = determineTributePairs(lastGameResult!, teams, hands, maxPlayers);
    _currentTributeIndex = 0;
    _waitingForHumanTribute = false;
    _processNextTribute();
  }

  void _processNextTribute() {
    if (_currentTributeIndex >= _pendingTributePairs.length) {
      onEvent('game:tribute-complete', {});
      phase = 'IDENTITY_REVEAL';
      _startIdentityPhase();
      return;
    }

    final pair = _pendingTributePairs[_currentTributeIndex];
    final card = applyTributeGive(hands, pair);

    if (card != null) {
      final winnerId = pair.toPlayerId;
      final loserId = pair.fromPlayerId;

      if (winnerId == 'p0') {
        // Human is winner — needs to choose a return card
        _waitingForHumanTribute = true;
        onEvent('game:tribute-return-request', {
          'fromPlayerId': loserId,
          'fromPlayerName': _playerName(loserId),
          'receivedCard': card,
          'hand': List<GameCard>.from(hands['p0'] ?? []),
        });
        return;
      }

      if (loserId == 'p0') {
        // Human is loser — auto-give highest card, inform and wait
        _waitingForHumanTribute = true;
        onEvent('game:tribute-give', {
          'fromPlayerId': 'p0',
          'toPlayerId': winnerId,
          'toPlayerName': _playerName(winnerId),
          'card': card,
        });
        return;
      }

      // AI winner chooses return card
      final winnerHand = hands[winnerId] ?? [];
      final returnCard = chooseTributeReturnCard(winnerHand, AIDifficulty.NORMAL);
      applyTributeReceive(hands, pair, returnCard);
    }

    _currentTributeIndex++;
    Future.delayed(const Duration(milliseconds: 500), _processNextTribute);
  }

  void handleTributeContinue() {
    if (!_waitingForHumanTribute) return;
    _waitingForHumanTribute = false;

    // Process AI return for the current pair (human was loser)
    final pair = _pendingTributePairs[_currentTributeIndex];
    final winnerHand = hands[pair.toPlayerId] ?? [];
    final returnCard = chooseTributeReturnCard(winnerHand, AIDifficulty.NORMAL);
    applyTributeReceive(hands, pair, returnCard);

    _currentTributeIndex++;
    _processNextTribute();
  }

  void handleTributeReturn(String cardId) {
    if (!_waitingForHumanTribute) return;
    _waitingForHumanTribute = false;

    final pair = _pendingTributePairs[_currentTributeIndex];
    final hand = hands['p0'] ?? [];
    final returnCard = hand.firstWhere((c) => c.id == cardId,
        orElse: () => hand.first);

    applyTributeReceive(hands, pair, returnCard);

    // Update human hand in UI
    onEvent('game:cards-remaining', {'counts': _opponentCounts()});
    onEvent('game:tribute-return-done', {
      'hand': List<GameCard>.from(hands['p0'] ?? []),
    });

    _currentTributeIndex++;
    _processNextTribute();
  }

  String _playerName(String id) {
    for (final p in players) {
      if (p['id'] == id) return p['name'] as String;
    }
    return id;
  }

  Map<String, int> _opponentCounts() {
    final counts = <String, int>{};
    for (var i = 1; i < maxPlayers; i++) {
      counts['p$i'] = hands['p$i']?.length ?? 0;
    }
    return counts;
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
      'revealedCards': List<Map<String, dynamic>>.from(revealedCards),
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
    final board = getBoardState(trickState);
    final isLeader = isTrickLeader(trickState, playerId);

    // Wind opportunity: next player after someone finished with board
    if (_windPending && !_freePlayMode) {
      if (playerId == 'p0') {
        // Ask human if they want to 要风
        onEvent('game:wind-request', {
          'board': board != null ? {
            'cards': board.cards,
            'playType': board.playType.name,
            'playedByPlayerId': board.playedByPlayerId,
          } : null,
          'finisherId': _windFinisherId,
          'finisherName': _playerName(_windFinisherId!),
        });
        return;
      } else {
        // AI decides
        _handleAIWindDecision(playerId);
        return;
      }
    }

    if (playerId == 'p0') {
      onEvent('game:turn-request', {
        'board': board != null ? {
          'cards': board.cards,
          'playType': board.playType.name,
          'playedByPlayerId': board.playedByPlayerId,
        } : null,
        'isFirstTrick': trickState.isFirstTrick,
        'isTrickLeader': isLeader,
      });
    } else if (_isAI(playerId)) {
      Future.delayed(Duration(milliseconds: 800 + _rng.nextInt(1500)), () {
        if (phase != 'PLAYING') return;
        if (getCurrentPlayerId(trickState) != playerId) return;
        _handleAITurn(playerId);
      });
    }
  }

  void _handleAIWindDecision(String aiId) {
    final hand = hands[aiId] ?? [];
    final board = getBoardState(trickState);

    // AI decides to 要风 based on difficulty
    bool takeWind = false;
    switch (difficulty) {
      case AIDifficulty.EASY:
        takeWind = _rng.nextDouble() < 0.4;
        break;
      case AIDifficulty.NORMAL:
        // Take wind if can't beat the board or has few cards left
        final legal = getAllLegalPlays(hand, board);
        takeWind = legal.isEmpty || hand.length <= 3;
        break;
      case AIDifficulty.HARD:
        // Strategically take wind when beneficial
        final legal = getAllLegalPlays(hand, board);
        takeWind = legal.isEmpty ||
            (hand.length <= 4 && legal.every((p) => p.length > 1));
        break;
    }

    if (takeWind) {
      _windRequesterId = aiId;
      // Check with other players
      _checkWindAgreement();
    } else {
      // Normal play
      _windPending = false;
      _handleAITurn(aiId);
    }
  }

  void handleWindRequest(bool takeWind) {
    if (!_windPending) return;
    if (takeWind) {
      _windRequesterId = 'p0';
      _checkWindAgreement();
    } else {
      _windPending = false;
      _requestTurn('p0');
    }
  }

  void _checkWindAgreement() {
    final others = trickState.activePlayerIds
        .where((id) => id != _windRequesterId && !finishOrder.contains(id))
        .toList();

    if (others.isEmpty) {
      _grantWind();
      return;
    }

    // Check if any human player among others
    if (others.contains('p0')) {
      onEvent('game:wind-agree-request', {
        'requesterId': _windRequesterId,
        'requesterName': _playerName(_windRequesterId!),
      });
      return; // wait for human response
    }

    // All AI — decide
    bool allAgreed = true;
    String? opposer;
    for (final id in others) {
      if (!_aiAgreesWind(id)) {
        allAgreed = false;
        opposer = id;
        break;
      }
    }

    if (allAgreed) {
      _grantWind();
    } else {
      _opposeWind(opposer!);
    }
  }

  bool _aiAgreesWind(String aiId) {
    final hand = hands[aiId] ?? [];
    switch (difficulty) {
      case AIDifficulty.EASY:
        return _rng.nextDouble() < 0.8;
      case AIDifficulty.NORMAL:
        return _rng.nextDouble() < 0.6;
      case AIDifficulty.HARD:
        // Oppose if can beat the board
        final legal = getAllLegalPlays(hand, _windBoard);
        return legal.isEmpty;
    }
  }

  void handleWindAgree(bool agree) {
    if (agree) {
      _grantWind();
    } else {
      _opposeWind('p0');
    }
  }

  void _grantWind() {
    _windPending = false;
    _freePlayMode = true;
    onEvent('game:wind-granted', {
      'requesterId': _windRequesterId,
      'requesterName': _playerName(_windRequesterId!),
    });
    _requestTurn(_windRequesterId!);
  }

  void _opposeWind(String opposerId) {
    _windPending = false;
    _freePlayMode = false;
    onEvent('game:wind-opposed', {
      'requesterId': _windRequesterId,
      'opposerId': opposerId,
      'opposerName': _playerName(opposerId),
    });
    // Opposer must beat the board — make them the current player
    if (opposerId == 'p0') {
      _requestTurn('p0');
    } else {
      _handleAITurn(opposerId);
    }
  }

  bool _isAI(String playerId) {
    for (final p in players) {
      if (p['id'] == playerId) return p['isAI'] as bool;
    }
    return false;
  }

  void _handleAITurn(String playerId) {
    final hand = hands[playerId] ?? [];
    final board = getBoardState(trickState);

    // Free play mode (wind granted) — play any valid cards
    if (_freePlayMode) {
      _freePlayMode = false;
      if (hand.isEmpty) {
        _applyPass(playerId);
        return;
      }
      // Play a single card or the best available play
      final decision = decideAI(hand, null, difficulty, true, []);
      if (decision.cards != null) {
        _applyPlay(playerId, decision.cards!);
      } else {
        _applyPlay(playerId, [hand.first]);
      }
      return;
    }

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

    if (_freePlayMode) {
      // Wind granted — validate only card type, not against board
      final playInfo = determinePlay(selectedCards);
      if (playInfo == null) {
        onEvent('game:error', {'message': '无效的牌型组合'});
        return;
      }
      _freePlayMode = false;
      _applyPlay('p0', selectedCards);
      return;
    }

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

      // Wind (送风): if player finished with a board, next player gets wind option
      final currentBoard = getBoardState(trickState);
      if (currentBoard != null && !_windPending) {
        _windPending = true;
        _windFinisherId = playerId;
        _windBoard = currentBoard;
      }
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
        _windPending = false;
        _freePlayMode = false;
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
        _windPending = false;
        _freePlayMode = false;
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
