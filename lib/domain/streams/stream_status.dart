enum StreamStatus { active, planned, finished }

extension StreamStatusLabel on StreamStatus {
  String get label => switch (this) {
    StreamStatus.active => 'Активные',
    StreamStatus.planned => 'Запланированные',
    StreamStatus.finished => 'Завершенные',
  };
}

/// то, что требует бэк
extension StreamStatusApi on StreamStatus {
  String get apiType => switch (this) {
    StreamStatus.active => 'active',
    StreamStatus.planned => 'future',
    StreamStatus.finished => 'completed',
  };
}

extension StreamStatusApiX on StreamStatus {
  static StreamStatus fromApi(String v) {
    switch (v) {
      case 'active':
        return StreamStatus.active;
      case 'future':
        return StreamStatus.planned;
      case 'completed':
        return StreamStatus.finished;
      default:
        return StreamStatus.active;
    }
  }
}
