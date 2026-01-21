import 'streams_item.dart';
import 'stream_status.dart';

class StreamsPage {
  final List<StreamItem> items;
  final int total;
  final int from;
  final int limit;

  const StreamsPage({
    required this.items,
    required this.total,
    required this.from,
    required this.limit,
  });
}

abstract class StreamsRepository {
  Future<StreamsPage> fetchStreams({
    required StreamStatus status,
    required int from,
    required int limit,
    required bool my, // если true -> добавляем user_id
  });
}
