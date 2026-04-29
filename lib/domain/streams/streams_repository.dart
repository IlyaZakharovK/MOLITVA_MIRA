import 'streams_item.dart';
import 'stream_status.dart';

class StreamsPage {
  final List<StreamItem> items;
  final int from;
  final int limit;

  const StreamsPage({
    required this.items,
    required this.from,
    required this.limit,
  });
}

abstract class StreamsRepository {
  Future<StreamsPage> fetchStreams({
    required StreamStatus status,
    required int from,
    required int limit,
    required bool my,
  });
}
