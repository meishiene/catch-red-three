import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_provider.dart';
import '../services/socket_service.dart';

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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('游戏即将开始...', style: TextStyle(fontSize: 24)),
              SizedBox(height: 16),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('等待玩家')),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            // Room code display
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: widget.roomCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('房间码已复制')),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD4380D)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text('房间码', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(
                      widget.roomCode,
                      style: const TextStyle(fontSize: 36, letterSpacing: 8, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text('点击复制', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text('玩家列表 (${_players.isEmpty ? 1 : _players.length}/${widget.maxPlayers})',
              style: const TextStyle(fontSize: 16),
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
                        child: Text(p['name'].toString()[0]),
                      ),
                      title: Text(p['name'] as String),
                      subtitle: Text(p['isAI'] == true ? 'AI' : '玩家'),
                    );
                  }
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person_add)),
                    title: const Text('等待中...', style: TextStyle(color: Colors.grey)),
                  );
                },
              ),
            ),
            if (widget.isHost)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _players.length >= 3 ? _startGame : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4380D),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('开始游戏'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _startGame() {
    ref.read(socketServiceProvider).emit('room:start');
  }
}
