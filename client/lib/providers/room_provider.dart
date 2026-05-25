import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/room.dart';
import 'app_provider.dart';

class RoomNotifier extends StateNotifier<RoomState?> {
  RoomNotifier() : super(null);

  void updateFromJson(Map<String, dynamic> json) {
    state = RoomState.fromJson(json);
  }

  void setStatus(String status) {
    if (state == null) return;
    state = RoomState(
      code: state!.code,
      hostPlayerId: state!.hostPlayerId,
      maxPlayers: state!.maxPlayers,
      status: status,
      players: state!.players,
    );
  }

  void clear() {
    state = null;
  }
}

final roomProvider = StateNotifierProvider<RoomNotifier, RoomState?>((ref) {
  return RoomNotifier();
});

final currentRoomCodeProvider = Provider<String?>((ref) {
  return ref.watch(roomProvider)?.code;
});
