import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_provider.dart';
import '../services/socket_service.dart';
import '../theme/app_theme.dart';

class WaitingRoomScreen extends ConsumerStatefulWidget {
  final String roomCode;
  final String playerName;
  final int maxPlayers;
  final bool isHost;

  const WaitingRoomScreen({
    super.key,
    required this.roomCode,
    required this.playerName,
    required this.maxPlayers,
    required this.isHost,
  });

  @override
  ConsumerState<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends ConsumerState<WaitingRoomScreen> {
  List<Map<String, dynamic>> _players = [];
  bool _gameStarting = false;

  @override
  void initState() {
    super.initState();
    ref.read(roomCodeProvider.notifier).state = widget.roomCode;
    ref.read(isHostProvider.notifier).state = widget.isHost;
    _listenToRoom();
  }

  void _listenToRoom() {
    final socket = ref.read(socketServiceProvider);
    socket.on<Map<String, dynamic>>('room:updated').listen((data) {
      if (mounted) {
        setState(() {
          _players = List<Map<String, dynamic>>.from(data['players'] as List);
        });
      }
    });

    socket.on<Map<String, dynamic>>('game:starting').listen((_) {
      if (mounted) {
        setState(() => _gameStarting = true);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/game');
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_gameStarting) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A3A1A), AppColors.tableDark],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('游戏即将开始...', style: TextStyle(fontSize: 24, color: Colors.white)),
                SizedBox(height: 16),
                CircularProgressIndicator(color: AppColors.gold),
              ],
            ),
          ),
        ),
      );
    }

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
                // Room code
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: widget.roomCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('房间码已复制'),
                        backgroundColor: AppColors.gold,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Text('房间码', style: TextStyle(color: Colors.white54)),
                        const SizedBox(height: 8),
                        Text(
                          widget.roomCode,
                          style: const TextStyle(
                            fontSize: 40,
                            letterSpacing: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text('点击复制', style: TextStyle(color: Colors.white24, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  '玩家列表 (${_players.isEmpty ? 1 : _players.length}/${widget.maxPlayers})',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.maxPlayers,
                    itemBuilder: (_, index) {
                      if (index < _players.length) {
                        final p = _players[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.gold.withOpacity(0.3),
                            child: Text(
                              p['name'].toString()[0],
                              style: const TextStyle(color: AppColors.gold),
                            ),
                          ),
                          title: Text(p['name'] as String,
                            style: const TextStyle(color: Colors.white)),
                          subtitle: Text(
                            p['isAI'] == true ? 'AI' : '玩家',
                            style: const TextStyle(color: Colors.white38),
                          ),
                        );
                      }
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.white12,
                          child: Icon(Icons.person_add, color: Colors.white24),
                        ),
                        title: const Text('等待中...',
                          style: TextStyle(color: Colors.white24)),
                      );
                    },
                  ),
                ),
                if (widget.isHost)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _players.length >= 3 ? _startGame : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.white12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('开始游戏', style: TextStyle(fontSize: 16)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startGame() {
    ref.read(socketServiceProvider).emit('room:start');
  }
}
