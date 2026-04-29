import 'request_status.dart';

class PrayerRequestItem {
  final String id;

  final bool isUrgent;

  final DateTime? dateTime;

  final String fromName;
  final String categoryOrPrayer;
  final String text;

  final RequestStatus status;

  const PrayerRequestItem({
    required this.id,
    required this.isUrgent,
    required this.dateTime,
    required this.fromName,
    required this.categoryOrPrayer,
    required this.text,
    required this.status,
  });

  PrayerRequestItem copyWith({
    bool? isUrgent,
    DateTime? dateTime,
    String? fromName,
    String? categoryOrPrayer,
    String? text,
    RequestStatus? status,
  }) {
    return PrayerRequestItem(
      id: id,
      isUrgent: isUrgent ?? this.isUrgent,
      dateTime: dateTime ?? this.dateTime,
      fromName: fromName ?? this.fromName,
      categoryOrPrayer: categoryOrPrayer ?? this.categoryOrPrayer,
      text: text ?? this.text,
      status: status ?? this.status,
    );
  }
}
