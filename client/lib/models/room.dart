class RoomState {
  final String code;
  final String hostPlayerId;
  final int maxPlayers;
  final String status;
  final List<RoomPlayer> players;

  RoomState({
    required this.code,
    required this.hostPlayerId,
    required this.maxPlayers,
    required this.status,
    required this.players,
  });

  factory RoomState.fromJson(Map<String, dynamic> json) => RoomState(
    code: json['code'] as String,
    hostPlayerId: json['hostPlayerId'] as String,
    maxPlayers: json['maxPlayers'] as int,
    status: json['status'] as String,
    players: (json['players'] as List)
        .map((p) => RoomPlayer.fromJson(p as Map<String, dynamic>))
        .toList(),
  );

  bool get isHost => true; // determined by provider
  bool get canStart => players.length >= 3 && status == 'waiting';
}

class RoomPlayer {
  final String id;
  final String name;
  final int seatIndex;
  final bool isConnected;
  final bool isAI;

  RoomPlayer({
    required this.id,
    required this.name,
    required this.seatIndex,
    required this.isConnected,
    required this.isAI,
  });

  factory RoomPlayer.fromJson(Map<String, dynamic> json) => RoomPlayer(
    id: json['id'] as String,
    name: json['name'] as String,
    seatIndex: json['seatIndex'] as int,
    isConnected: json['isConnected'] as bool,
    isAI: json['isAI'] as bool? ?? false,
  );
}
