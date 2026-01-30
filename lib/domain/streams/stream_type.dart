enum StreamType { open, closed, family, sos , nodata}

extension StreamTypeIDLabel on StreamType {
  String get label => switch (this) {
    StreamType.open => 'Открытая',
    StreamType.closed => 'Закрытая',
    StreamType.family => 'Семейная',
    StreamType.sos => 'SOS',
    StreamType.nodata => 'Нет данных'
  };
}

extension StreamTypeIDApiX on StreamType {
  static StreamType fromApi(int v) {
    switch (v) {
      case 1:
        return StreamType.open;
      case 2:
        return StreamType.closed;
      case 3:
        return StreamType.family;
      case 4:
        return StreamType.sos;
      default:
        return StreamType.nodata;
    }
  }
}