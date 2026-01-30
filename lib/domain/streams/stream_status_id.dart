enum StreamStatusID { moderated, blessed, blocked, deleted, nodata }

extension StreamStatusIDIDLabel on StreamStatusID {
  String get label => switch (this) {
    StreamStatusID.moderated => 'На модерации',
    StreamStatusID.blessed => 'Благословлена',
    StreamStatusID.blocked => 'Заблокирована',
    StreamStatusID.deleted => 'Удалена пользователем',
    StreamStatusID.nodata => 'Нет данных',
  };
}

extension StreamStatusIDApiX on StreamStatusID {
  static StreamStatusID fromApi(int v) {
    switch (v) {
      case 1:
        return StreamStatusID.moderated;
      case 2:
        return StreamStatusID.blessed;
      case 3:
        return StreamStatusID.blocked;
      case 4:
        return StreamStatusID.deleted;
      default:
        return StreamStatusID.nodata;
    }
  }
}