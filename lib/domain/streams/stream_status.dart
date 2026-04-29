enum StreamStatus { active, planned, finished, blocked }

extension StreamStatusLabel on StreamStatus {
  String label({bool my = false}) => switch (this) {
    StreamStatus.active => 'Активные',
    StreamStatus.planned => my ? 'Запланированные' : 'Предстоящие',
    StreamStatus.finished => 'Завершенные',
    StreamStatus.blocked => 'Отклоненные',
  };
}

extension StreamStatusApi on StreamStatus {
  String get apiType => switch (this) {
    StreamStatus.active => 'active',
    StreamStatus.planned => 'future',
    StreamStatus.finished => 'completed',
    StreamStatus.blocked => 'declined',
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
      case 'declined':
        return StreamStatus.blocked;
      default:
        return StreamStatus.active;
    }
  }
}
