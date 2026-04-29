class RequestModerationItem {
  final int id;
  final int statusId;
  final int typeId;
  final String title;
  final String message;

  final String authorName;
  final String categoryName;
  final String prayerName;

  final DateTime createdAt;
  final DateTime startAt;

  const RequestModerationItem({
    required this.id,
    required this.statusId,
    required this.typeId,
    required this.title,
    required this.message,
    required this.authorName,
    required this.categoryName,
    required this.prayerName,
    required this.createdAt,
    required this.startAt,
  });

  bool get isSos => typeId == 4;

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (v is DateTime) return v;
    final s = v.toString().trim();
    final iso = DateTime.tryParse(s);
    if (iso != null) return iso;

    try {
      final parts = s.split(' ');
      final d = parts[0].split('.');
      final t = (parts.length > 1 ? parts[1] : '00:00').split(':');
      final day = int.parse(d[0]);
      final month = int.parse(d[1]);
      final year = int.parse(d[2]);
      final hour = int.parse(t[0]);
      final minute = int.parse(t[1]);
      return DateTime(year, month, day, hour, minute);
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  factory RequestModerationItem.fromJson(Map<String, dynamic> json) {
    int _int(dynamic v, {int def = 0}) {
      if (v == null) return def;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? def;
    }

    String _str(dynamic v, {String def = ''}) {
      if (v == null) return def;
      return v.toString();
    }

    final id = _int(json['id']);
    final statusId = _int(json['status_id'] ?? json['statusId']);
    final typeId = _int(json['type'] ?? json['typeId']);

    final title =
    _str(json['title'] ?? json['name'] ?? json['translation_name'] ?? '—');
    final message = _str(json['message'] ??
        json['text'] ??
        json['description'] ??
        json['comment'] ??
        '');

    final authorName = _str(json['author_name'] ??
        json['author'] ??
        json['owner_name'] ??
        '—');
    final categoryName = _str(json['prayers_category_name'] ?? json['category'] ?? '—');
    final prayerName =
    _str(json['prayers_texts_name'] ?? json['prayer'] ?? 'Не выбрано');

    final createdAt = _parseDate(json['date_add'] ?? json['date_create']);
    final startAt = _parseDate(json['date_planned'] ?? json['date_start']);

    return RequestModerationItem(
      id: id,
      statusId: statusId,
      typeId: typeId,
      title: title,
      message: message,
      authorName: authorName,
      categoryName: categoryName,
      prayerName: prayerName,
      createdAt: createdAt,
      startAt: startAt,
    );
  }
}
