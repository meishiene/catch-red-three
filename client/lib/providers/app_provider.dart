import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/socket_service.dart';

final nicknameProvider = StateProvider<String>((ref) => '');
final playerIdProvider = StateProvider<String>((ref) => '');
final roomCodeProvider = StateProvider<String>((ref) => '');
final isHostProvider = StateProvider<bool>((ref) => false);
final isSinglePlayerProvider = StateProvider<bool>((ref) => false);
final aiDifficultyProvider = StateProvider<String>((ref) => 'NORMAL');
final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService();
});
