import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_provider.dart';
import '../services/socket_service.dart';

class CreateRoomScreen extends ConsumerStatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  int _selectedPlayers = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('创建房间')),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('选择游戏人数', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [3, 4, 5].map((n) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ChoiceChip(
                  label: Text('$n人'),
                  selected: _selectedPlayers == n,
                  onSelected: (_) => setState(() => _selectedPlayers = n),
                ),
              )).toList(),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _createRoom,
                icon: const Icon(Icons.add),
                label: const Text('创建房间'),
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

  void _createRoom() async {
    final name = ref.read(nicknameProvider);
    try {
      final socket = ref.read(socketServiceProvider);
      await socket.connect('http://YOUR_SERVER_IP:3000');

      final result = await socket.emitWithAck('room:create', {
        'playerName': name,
        'maxPlayers': _selectedPlayers,
      });

      if (result['error'] != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] as String)),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/waiting-room', arguments: {
          'roomCode': result['roomCode'],
          'playerName': name,
          'maxPlayers': _selectedPlayers,
          'isHost': true,
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
