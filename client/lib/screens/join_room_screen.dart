import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_provider.dart';
import '../services/socket_service.dart';

class JoinRoomScreen extends ConsumerStatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  ConsumerState<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends ConsumerState<JoinRoomScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('加入房间')),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('输入房间码', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(fontSize: 32, letterSpacing: 8),
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _joinRoom,
                icon: const Icon(Icons.login),
                label: const Text('加入房间'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4380D),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _joinRoom() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    final name = ref.read(nicknameProvider);
    try {
      final socket = ref.read(socketServiceProvider);
      await socket.connect('http://YOUR_SERVER_IP:3000');

      final result = await socket.emitWithAck('room:join', {
        'roomCode': code,
        'playerName': name,
      });

      if (result['error'] != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] as String)),
          );
        }
        return;
      }

      final room = result['room'] as Map<String, dynamic>;
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/waiting-room', arguments: {
          'roomCode': code,
          'playerName': name,
          'maxPlayers': room['maxPlayers'],
          'isHost': false,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('连接失败: $e')),
        );
      }
    }
  }
}
