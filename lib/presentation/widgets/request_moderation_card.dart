import 'package:flutter/material.dart';
import 'package:vsem_mirom/domain/streams/stream_status.dart';
import 'package:vsem_mirom/domain/streams/stream_status_id.dart';

import '../../domain/request_moderation/request_moderation_item.dart';
import '../../domain/streams/stream_type.dart';

class RequestModerationCard extends StatelessWidget {
  final RequestModerationItem item;

  /// 1=новые, 2=благословленные, 3=отклоненные
  final int statusId;

  final VoidCallback? onBless;
  final VoidCallback? onReject;

  const RequestModerationCard({
    super.key,
    required this.item,
    required this.statusId,
    this.onBless,
    this.onReject,
  });

  String _fmt(DateTime dt) {
    String two(int v) => v < 10 ? '0$v' : '$v';
    return '${two(dt.day)}.${two(dt.month)}.${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }

  TableRow _row(String k, String v, {bool alt = false}) {
    return TableRow(
      decoration: BoxDecoration(
        color: alt ? const Color(0xFFEFEFEF) : Colors.white,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            k,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            v,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Color _statusBg(int s) {
    switch (s) {
      case 1:
        return const Color(0xFF1B8F2E);
      case 2:
        return const Color(0xFFFFC107);
      case 3:
        return const Color(0xFF3F4F86);
      case 4:
        return const Color(0xFFE53935);
      default:
        return const Color(0xFFE0E0E0);
    }
  }

  String _statusText(int s){
    switch (s) {
      case 1:
        return "Открытая";
      case 2:
        return "Закрытая";
      case 3:
        return "Семейная";
      case 4:
        return "SOS - срочная";
      default:
        return "Нет данных";
    }
  }

  @override
  Widget build(BuildContext context) {
    final showActions = statusId == 1;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            color: Color(0x11000000),
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people_alt_outlined, size: 40, color: Colors.black26),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _statusBg(item.typeId),
                          borderRadius: BorderRadius.circular(3)
                        ),
                        child: Text(
                          _statusText(item.typeId),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          if (item.message.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(
                item.message,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            )
          else
            const SizedBox.shrink(),

          const SizedBox(height: 14),

          Table(
            border: TableBorder.all(color: Colors.black12, width: 1),
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(2.2),
            },
            children: [
              _row('Автор', item.authorName, alt: true),
              _row('Категория', item.categoryName, alt: false),
              _row('Молитва', item.prayerName, alt: true),
              _row('Дата создания', _fmt(item.createdAt), alt: false),
              _row('Дата начала', item.isSos ? 'Немедленно' : _fmt(item.startAt), alt: true),
            ],
          ),

          if (!showActions) const SizedBox(height: 4),

          if (showActions) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: onBless,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDFF6F3),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Благословить',
                  style: TextStyle(
                    color: Color(0xFF0E8E7B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: onReject,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFBE6E6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Отклонить',
                  style: TextStyle(
                    color: Color(0xFFE04B4B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
