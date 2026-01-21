import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart';

import '../shell/app_shell.dart';
import '../../domain/prayer_request/prayer_request_mode.dart';
import '../widgets/app_message_bar.dart';
import '../widgets/top_bar.dart';
import 'prayer_request_controller.dart';

class PrayerRequestScreen extends ConsumerStatefulWidget {
  const PrayerRequestScreen({super.key});

  @override
  ConsumerState<PrayerRequestScreen> createState() => _PrayerRequestScreenState();
}

class _PrayerRequestScreenState extends ConsumerState<PrayerRequestScreen> {
  static const _blue = Color(0xFF3F4F86);

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  bool _open = true;
  bool _family = false;
  DateTime? _dateTime;

  final _selfPrayText = TextEditingController();

  Future<int?> _pickFromSearchSheet({
    required String title,
    required List<(int id, String name)> items,
    required int? selectedId,
  }) async {
    final ctrl = TextEditingController();

    return showModalBottomSheet<int?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (ctx, scrollCtrl) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF3F4F86),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(null),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: TextField(
                      controller: ctrl,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Поиск...',
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFF6F7F9),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.black26),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.black45),
                        ),
                      ),
                    ),
                  ),

                  const Divider(height: 1),

                  Expanded(
                    child: StatefulBuilder(
                      builder: (ctx, setModalState) {
                        ctrl.addListener(() => setModalState(() {}));

                        final q = ctrl.text.trim().toLowerCase();
                        final filtered = q.isEmpty
                            ? items
                            : items.where((e) => e.$2.toLowerCase().contains(q)).toList();

                        return ListView.separated(
                          controller: scrollCtrl,
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final id = filtered[i].$1;
                            final name = filtered[i].$2;
                            final selected = id == selectedId;

                            return ListTile(
                              title: Text(
                                name,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              trailing: selected
                                  ? const Icon(Icons.check, color: Color(0xFF3F4F86))
                                  : null,
                              onTap: () => Navigator.of(ctx).pop(id),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }


  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _selfPrayText.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date == null) return;

    final initialTime = TimeOfDay.fromDateTime(_dateTime ?? now);

    final time = await _pickCupertinoTime(
      context: context,
      initial: initialTime,
      accent: _blue,
    );
    if (time == null) return;

    setState(() {
      _dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<TimeOfDay?> _pickCupertinoTime({
    required BuildContext context,
    required TimeOfDay initial,
    required Color accent,
  }) async {
    Duration temp = Duration(hours: initial.hour, minutes: initial.minute);

    return showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: 320,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(null),
                      child: Text(
                        'Отмена',
                        style: TextStyle(color: accent, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(
                        TimeOfDay(
                          hour: temp.inHours % 24,
                          minute: temp.inMinutes % 60,
                        ),
                      ),
                      child: Text(
                        'Готово',
                        style: TextStyle(color: accent, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoTheme(
                  data: const CupertinoThemeData(brightness: Brightness.light),
                  child: CupertinoTimerPicker(
                    mode: CupertinoTimerPickerMode.hm,
                    initialTimerDuration: temp,
                    minuteInterval: 1,
                    onTimerDurationChanged: (d) => temp = d,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isValidEmail(String email) {
    final e = email.trim();
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return re.hasMatch(e);
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(prayerRequestModeProvider);
    final isSos = mode == PrayerRequestMode.sos;

    final st = ref.watch(prayerRequestControllerProvider);
    final ctrl = ref.read(prayerRequestControllerProvider.notifier);

    // Сообщение об ошибке — единообразно, над полями
    final error = st.errorMessage;

    return AppShell(
      child: SafeArea(
        child: Column(
          children: [
            const TopBar(title: 'Запрос на молитву'),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  if (error != null) ...[
                    _Card(
                      child: Text(
                        error,
                        style: const TextStyle(color: Color(0xFFFF6A00), fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  _Card(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            showAppMessageBar(context, 'Находится в разработке');
                          },
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: isSos ? const Color(0xFFFF6B6B) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFF6B6B)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'SOS',
                              style: TextStyle(
                                color: isSos ? Colors.white : const Color(0xFFFF6B6B),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        if (isSos) ...[
                          const SizedBox(height: 12),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Срочный запрос на молитву',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (isSos) ...[
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Label('Запрос:'),
                          _TextArea(controller: _nameCtrl, rows: 8),
                        ],
                      ),
                    ),
                  ] else ...[
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Label('Название:'),
                          _TextArea(
                            controller: _nameCtrl,
                            rows: 1,
                            onChanged: (_) => ctrl.clearError(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Label('Описание:'),
                          _TextArea(
                            controller: _descCtrl,
                            rows: 5,
                            onChanged: (_) => ctrl.clearError(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ====== БЛОК МОЛИТВ ======
                    if (!st.selfPray) ...[
                      _Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _Label('Категория'),

                            if (st.categoriesLoading)
                              const Padding(
                                padding: EdgeInsets.only(top: 6, bottom: 6),
                                child: LinearProgressIndicator(minHeight: 2),
                              ),

                            _InkField(
                              value: st.categoryId == null
                                  ? '--выберите категорию--'
                                  : (st.categories.firstWhere((c) => c.id == st.categoryId).name),
                              enabled: !st.selfPray && !st.categoriesLoading,
                              onTap: () async {
                                final picked = await _pickFromSearchSheet(
                                  title: 'Выберите категорию',
                                  items: st.categories.map((c) => (c.id, c.name)).toList(),
                                  selectedId: st.categoryId,
                                );
                                if (picked == null) return;
                                await ctrl.selectCategory(picked);
                              },
                            ),

                            const SizedBox(height: 12),

                            const SizedBox(height: 12),
                            const _Label('Молитва'),

                            if (st.prayersLoading)
                              const Padding(
                                padding: EdgeInsets.only(top: 6, bottom: 6),
                                child: LinearProgressIndicator(minHeight: 2),
                              ),

                            _InkField(
                              value: st.categoryId == null
                                  ? '--выберите категорию--'
                                  : (st.prayerId == null
                                  ? '--выберите молитву--'
                                  : (st.prayers.firstWhere((p) => p.id == st.prayerId).name)),
                              enabled: !st.selfPray && st.categoryId != null && !st.prayersLoading,
                              onTap: () async {
                                if (st.categoryId == null) return;

                                final picked = await _pickFromSearchSheet(
                                  title: 'Выберите молитву',
                                  items: st.prayers.map((p) => (p.id, p.name)).toList(),
                                  selectedId: st.prayerId,
                                );
                                if (picked == null) return;
                                ctrl.selectPrayer(picked);
                              },
                            ),

                            Row(
                              children: [
                                Checkbox(
                                  value: st.selfPray,
                                  onChanged: (v) => ctrl.setSelfPray(v ?? false),
                                  activeColor: Colors.black87,
                                ),
                                const Text(
                                  'Своя молитва',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),

                            const _Label('Текст молитвы'),
                            Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(maxHeight: 170),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6F7F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.black26),
                              ),
                              child: Scrollbar(
                                thumbVisibility: true,
                                child: SingleChildScrollView(
                                  child: Text(
                                    st.prayerText.isEmpty
                                        ? 'Выберите молитву — здесь появится текст'
                                        : st.prayerText,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.35,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ] else ...[
                      _Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _Label('Текст молитвы:'),
                            _TextArea(
                              controller: _selfPrayText,
                              rows: 5,
                              onChanged: (_) => ctrl.clearError(),
                            ),
                            Row(
                              children: [
                                Checkbox(
                                  value: st.selfPray,
                                  onChanged: (v) => ctrl.setSelfPray(v ?? false),
                                  activeColor: Colors.black87,
                                ),
                                const Text(
                                  'Своя молитва',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RadioListTile<bool>(
                            contentPadding: EdgeInsets.zero,
                            value: true,
                            groupValue: _open,
                            onChanged: (_) => setState(() => _open = true),
                            title: const Text('Открытая молитва'),
                            activeColor: Colors.black87,
                          ),
                          RadioListTile<bool>(
                            contentPadding: EdgeInsets.zero,
                            value: false,
                            groupValue: _open,
                            onChanged: (_) => setState(() => _open = false),
                            title: const Text('Закрытая молитва'),
                            activeColor: Colors.black87,
                          ),
                          const SizedBox(height: 8),

                          _DateTimeField(
                            value: _dateTime,
                            onPick: _pickDateTime,
                            onClear: () => setState(() => _dateTime = null),
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Checkbox(
                                value: _family,
                                onChanged: (v) => setState(() => _family = v ?? false),
                                activeColor: Colors.black87,
                              ),
                              const Text(
                                'Семейная молитва',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  SizedBox(
                    height: 44,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      onPressed: st.isSubmitting
                          ? null
                          : () async {
                        // SOS пока не делаем
                        if (isSos) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('SOS находится в разработке')),
                          );
                          return;
                        }

                        final name = _nameCtrl.text.trim();
                        final desc = _descCtrl.text.trim();

                        if (name.isEmpty) {
                          ctrl.clearError();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Введите название')),
                          );
                          return;
                        }

                        if (_dateTime == null) {
                          ctrl.clearError();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Выберите дату и время')),
                          );
                          return;
                        }

                        if (st.selfPray) {
                          if (_selfPrayText.text.trim().isEmpty) {
                            ctrl.clearError();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Введите текст своей молитвы')),
                            );
                            return;
                          }
                        } else {
                          if (st.categoryId == null) {
                            ctrl.clearError();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Выберите категорию')),
                            );
                            return;
                          }
                          if (st.prayerId == null) {
                            ctrl.clearError();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Выберите молитву')),
                            );
                            return;
                          }
                        }

                        try {
                          await ctrl.submitTranslation(
                            name: name,
                            description: desc,
                            type: _open ? 1 : 2,
                            datePlanned: _dateTime!,
                            selfPray: st.selfPray,
                            selfPrayText: _selfPrayText.text.trim(),
                          );

                          if (!mounted) return;

                          setState(() {
                            _nameCtrl.clear();
                            _descCtrl.clear();
                            _selfPrayText.clear();
                            _dateTime = null;
                            _open = true;
                            _family = false;
                          });

                          ref.read(prayerRequestControllerProvider.notifier).setSelfPray(false);
                          ref.read(prayerRequestControllerProvider.notifier).selectCategory(null);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Трансляция создана')),
                          );
                        } catch (_) {
                          // ошибка уже в state.errorMessage
                        }
                      },
                      child: st.isSubmitting
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : const Text('Создать заявку'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            color: Color(0x14000000),
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      ),
    );
  }
}

class _TextArea extends StatelessWidget {
  final TextEditingController controller;
  final int rows;
  final ValueChanged<String>? onChanged;

  const _TextArea({
    required this.controller,
    required this.rows,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLines: rows,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black26),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black45),
        ),
      ),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  final DateTime? value;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _DateTimeField({
    required this.value,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? 'Выберите дату и время'
        : '${value!.day.toString().padLeft(2, '0')}.${value!.month.toString().padLeft(2, '0')}.${value!.year} '
        '${value!.hour.toString().padLeft(2, '0')}:${value!.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black26),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ),
            if (value != null)
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close, size: 18),
              )
            else
              const Icon(Icons.calendar_today, size: 18, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}

class _InkField extends StatelessWidget {
  final String value;
  final bool enabled;
  final VoidCallback onTap;

  const _InkField({
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 44,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black26),
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: enabled ? Colors.black54 : Colors.black38,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.expand_more, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}

