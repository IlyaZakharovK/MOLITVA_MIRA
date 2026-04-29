// /mnt/data/sfu_ws_client.dart
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

typedef JsonMap = Map<String, dynamic>;

class SfuWsClient {
  SfuWsClient({required this.wsUrl});

  final String wsUrl;

  WebSocketChannel? _ch;
  StreamSubscription? _sub;
  Timer? _pingTimer;

  final _incoming = StreamController<JsonMap>.broadcast();
  Stream<JsonMap> get stream => _incoming.stream;

  Future<void> connect() async {
    if (_ch != null) return;

    _ch = WebSocketChannel.connect(Uri.parse(wsUrl));

    _sub = _ch!.stream.listen((event) {
      try {
        final decoded = jsonDecode(event.toString());
        if (decoded is Map) _incoming.add(Map<String, dynamic>.from(decoded));
      } catch (_) {}
    }, onError: (e) {
      _incoming.add({'status': 'error', 'msg': e.toString()});
    }, onDone: () {
      _incoming.add({'status': 'error', 'msg': 'WS closed'});
    });

    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      send({'type': 'ping'});
    });
  }

  void send(JsonMap payload) {
    _ch?.sink.add(jsonEncode(payload));
  }

  Future<void> join({required int roomId, required String pin}) async {
    send({'type': 'join', 'roomID': roomId, 'pin': pin});
  }

  Future<void> close() async {
    _pingTimer?.cancel();
    _pingTimer = null;

    await _sub?.cancel();
    _sub = null;

    try {
      await _ch?.sink.close();
    } catch (_) {}
    _ch = null;

    if (!_incoming.isClosed) {
      await _incoming.close();
    }
  }
}
