import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  late io.Socket _socket;
  final _eventControllers = <String, StreamController<dynamic>>{};
  bool _isConnected = false;
  String? _playerId;
  String? _roomCode;

  bool get isConnected => _isConnected;
  String? get playerId => _playerId;

  Future<void> connect(String uri) async {
    _socket = io.io(uri, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'reconnection': true,
      'reconnectionAttempts': 5,
      'reconnectionDelay': 2000,
    });

    _socket.onConnect((_) {
      _isConnected = true;
    });

    _socket.onDisconnect((_) {
      _isConnected = false;
    });

    _socket.connect();
  }

  Future<Map<String, dynamic>> emitWithAck(String event, [dynamic data]) {
    final completer = Completer<Map<String, dynamic>>();
    _socket.emitWithAck(event, data, ack: (response) {
      completer.complete(response is Map ? Map<String, dynamic>.from(response) : {});
    });
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('Server did not respond'),
    );
  }

  Stream<T> on<T>(String event) {
    if (!_eventControllers.containsKey(event)) {
      final controller = StreamController<T>.broadcast();
      _socket.on(event, (data) => controller.add(data as T));
      _eventControllers[event] = controller;
    }
    return _eventControllers[event]!.stream.cast<T>();
  }

  void emit(String event, [dynamic data]) {
    _socket.emit(event, data);
  }

  void setSession(String playerId, String roomCode) {
    _playerId = playerId;
    _roomCode = roomCode;
  }

  void dispose() {
    for (final c in _eventControllers.values) {
      c.close();
    }
    _socket.dispose();
  }
}
