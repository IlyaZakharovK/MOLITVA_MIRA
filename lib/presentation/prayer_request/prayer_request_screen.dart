import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart';

import '../../domain/prayer_request/pray_prams.dart';
import '../../domain/profile/profile_role.dart';
import '../../domain/streams/stream_status.dart';
import '../shell/app_shell.dart';
import '../streams/streams_screen.dart';
import '../widgets/app_message_bar.dart';
import '../widgets/top_bar.dart';
import 'prayer_request_controller.dart';

class PrayerRequestScreen extends ConsumerStatefulWidget {
  final PrayPrams params;

  const PrayerRequestScreen({
    super.key,
    this.params = const PrayPrams(
      categoryId: -1,
      categoryName: "-1",
      prayId: -1,
      prayName: '-1',
      prayText: '-1',
    ),
  });

  @override
  ConsumerState<PrayerRequestScreen> createState() =>
      _PrayerRequestScreenState();
}

class _PrayerRequestScreenState extends ConsumerState<PrayerRequestScreen> {
  static const _blue = Color(0xFF3F4F86);

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _selfPrayText = TextEditingController();

  int _translationType =
  1; // 1-open, 2-closed, 3-family, 4-sos (но sos берём из mode)
  DateTime? _dateTime;

  bool _isSos = false;

  final Map<String, String?> _errors = {};

  // ===== Prefill from PraysScreen =====
  late final PrayPrams _incoming;
  bool _prefillStarted = false;

  bool get _hasIncomingParams {
    // default values are -1 / '-1'
    return (_incoming.categoryId > 0) ||
        (_incoming.prayId > 0) ||
        (_incoming.prayText.isNotEmpty && _incoming.prayText != '-1') ||
        (_incoming.categoryName.isNotEmpty && _incoming.categoryName != '-1') ||
        (_incoming.prayName.isNotEmpty && _incoming.prayName != '-1');
  }

  int? get _incomingCategoryId =>
      _incoming.categoryId > 0 ? _incoming.categoryId : null;

  int? get _incomingPrayId => _incoming.prayId > 0 ? _incoming.prayId : null;

  String? get _incomingCategoryName =>
      (_incoming.categoryName.isNotEmpty && _incoming.categoryName != '-1')
          ? _incoming.categoryName
          : null;

  String? get _incomingPrayName =>
      (_incoming.prayName.isNotEmpty && _incoming.prayName != '-1')
          ? _incoming.prayName
          : null;

  String? get _incomingPrayText =>
      (_incoming.prayText.isNotEmpty && _incoming.prayText != '-1')
          ? _incoming.prayText
          : null;

  String _resolveCategoryName(PrayerRequestState st, int? id) {
    if (id == null) return '-- Не выбрано --';
    for (final c in st.categories) {
      if (c.id == id) return c.name;
    }
    if (id == _incomingCategoryId && _incomingCategoryName != null) {
      return _incomingCategoryName!;
    }
    return '-- Не выбрано --';
  }

  String _resolvePrayerName(PrayerRequestState st, int? id) {
    if (id == null) return '--выберите молитву--';
    for (final p in st.prayers) {
      if (p.id == id) return p.name;
    }
    if (id == _incomingPrayId && _incomingPrayName != null) {
      return _incomingPrayName!;
    }
    return '--выберите молитву--';
  }

  Future<void> _applyIncomingPrefill() async {
    if (_prefillStarted) return;
    _prefillStarted = true;

    if (!_hasIncomingParams) return;

    final ctrl = ref.read(prayerRequestControllerProvider.notifier);

    // 1) Prefill category (loads prayers list)
    final catId = _incomingCategoryId;
    if (catId != null) {
      try {
        await ctrl.selectCategory(catId);
      } catch (_) {}
    }

    // 2) Prefill prayer (wait until prayers loaded)
    final prayId = _incomingPrayId;
    if (prayId != null) {
      for (var i = 0; i < 25; i++) {
        final st = ref.read(prayerRequestControllerProvider);
        final ready =
            !st.prayersLoading && st.prayers.any((p) => p.id == prayId);
        if (ready) break;
        await Future.delayed(const Duration(milliseconds: 120));
      }

      final st2 = ref.read(prayerRequestControllerProvider);
      if (!st2.prayersLoading && st2.prayers.any((p) => p.id == prayId)) {
        try {
          ctrl.selectPrayer(prayId);
        } catch (_) {}
      }
    }
  }

  static const _kName = 'name';
  static const _kDesc = 'desc';
  static const _kDateTime = 'datetime';
  static const _kCategory = 'category';
  static const _kPrayer = 'prayer';
  static const _kSelfText = 'selfText';

  void _setError(String key, String? message) => _errors[key] = message;

  void _clearField(String key) {
    if (_errors.containsKey(key)) {
      setState(() => _errors.remove(key));
    }
  }

  bool _validateAndShow(PrayerRequestState st) {
    _errors.clear();

    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final selfText = _selfPrayText.text.trim();

    String? firstError;

    if (_isSos) {
      // ✅ SOS: только описание + категория
      if (desc.isEmpty) {
        _setError(_kDesc, 'Введите описание');
        firstError ??= 'Введите описание';
      }
      if (st.categoryId == null) {
        _setError(_kCategory, 'Выберите категорию');
        firstError ??= 'Выберите категорию';
      }

      setState(() {});
      if (firstError != null) {
        showAppMessageBar(context, firstError);
        return false;
      }
      return true;
    }

    // ✅ NORMAL: как было
    if (name.isEmpty) {
      _setError(_kName, 'Введите название');
      firstError ??= 'Введите название';
    }

    if (_dateTime == null) {
      _setError(_kDateTime, 'Выберите дату и время');
      firstError ??= 'Выберите дату и время';
    }

    if (st.selfPray) {
      if (selfText.isEmpty) {
        _setError(_kSelfText, 'Введите текст своей молитвы');
        firstError ??= 'Введите текст своей молитвы';
      }
    } else {
      if (st.categoryId == null) {
        _setError(_kCategory, 'Выберите категорию');
        firstError ??= 'Выберите категорию';
      }
      if (st.prayerId == null) {
        _setError(_kPrayer, 'Выберите молитву');
        firstError ??= 'Выберите молитву';
      }
    }

    setState(() {});

    if (firstError != null) {
      showAppMessageBar(context, firstError);
      return false;
    }
    return true;
  }

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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
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
                            : items
                            .where((e) => e.$2.toLowerCase().contains(q))
                            .toList();

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
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: selected
                                  ? const Icon(
                                Icons.check,
                                color: Color(0xFF3F4F86),
                              )
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
  void initState() {
    super.initState();
    _incoming = widget.params;

    // Prefill category/prayer if они переданы из списка молитв
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyIncomingPrefill();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _selfPrayText.dispose();
    super.dispose();
  }

  // ✅ вернул / оставил date+time picker (как у тебя)
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
      _dateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _clearField(_kDateTime);
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
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w800,
                        ),
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
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w800,
                        ),
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

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(prayerRequestControllerProvider);
    final ctrl = ref.read(prayerRequestControllerProvider.notifier);

    // ошибки из controller → showAppMessageBar
    ref.listen(prayerRequestControllerProvider.select((s) => s.errorMessage), (
        prev,
        next,
        ) {
      if (!context.mounted) return;
      if (next != null && next.isNotEmpty && next != prev) {
        showAppMessageBar(context, next);
      }
    });

    final sosColor = const Color(0xFFFF6B6B);
    final canUseSelfPrayer =
        st.role != ProfileRole.layman || st.canBlass;

    // Используем переданные параметры как "fallback", пока контроллер не догрузил списки.
    final effectiveCategoryId = st.categoryId ?? _incomingCategoryId;
    final effectivePrayerId = st.prayerId ?? _incomingPrayId;
    final effectivePrayerText = st.prayerText.isNotEmpty
        ? st.prayerText
        : (_incomingPrayText ?? '');

    return AppShell(
      child: SafeArea(
        child: Column(
          children: [
            const TopBar(title: 'Запрос на молитву'),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  // ===== SOS =====
                  _Card(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isSos = !_isSos;
                              _errors.clear();
                            });

                            // В SOS выключаем "свою молитву" (чтобы не ломать выбор категории)
                            if (_isSos && st.selfPray) {
                              ctrl.setSelfPray(false);
                            }

                            showAppMessageBar(
                              context,
                              _isSos
                                  ? 'SOS режим включён'
                                  : 'SOS режим выключен',
                            );
                          },
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: _isSos ? sosColor : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: sosColor),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'SOS',
                              style: TextStyle(
                                color: _isSos ? Colors.white : sosColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        if (_isSos) ...[
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

                  // ===== SOS: ТОЛЬКО 2 ПОЛЯ =====
                  if (_isSos) ...[
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Label('Описание трансляции'),
                          _TextArea(
                            controller: _descCtrl,
                            rows: 5,
                            error: _errors[_kDesc],
                            onChanged: (_) => _clearField(_kDesc),
                          ),
                          const SizedBox(height: 12),

                          const _Label('Категория'),
                          if (st.categoriesLoading)
                            const Padding(
                              padding: EdgeInsets.only(top: 6, bottom: 6),
                              child: LinearProgressIndicator(minHeight: 2),
                            ),
                          _InkField(
                            value: _resolveCategoryName(
                              st,
                              effectiveCategoryId,
                            ),
                            enabled: !st.categoriesLoading,
                            error: _errors[_kCategory],
                            onTap: () async {
                              final picked = await _pickFromSearchSheet(
                                title: 'Выберите категорию',
                                items: st.categories
                                    .map((c) => (c.id, c.name))
                                    .toList(),
                                selectedId: effectiveCategoryId,
                              );
                              if (picked == null) return;
                              await ctrl.selectCategory(picked);
                              _clearField(_kCategory);
                            },
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // ===== NORMAL UI (как у тебя было) =====
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Label('Название:'),
                          _TextArea(
                            controller: _nameCtrl,
                            rows: 1,
                            error: _errors[_kName],
                            onChanged: (_) => _clearField(_kName),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Label('Описание трансляции'),
                          _TextArea(
                            controller: _descCtrl,
                            rows: 5,
                            error: _errors[_kDesc],
                            onChanged: (_) => _clearField(_kDesc),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ===== БЛОК МОЛИТВ =====
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
                              value: _resolveCategoryName(
                                st,
                                effectiveCategoryId,
                              ),
                              enabled: !st.categoriesLoading,
                              error: _errors[_kCategory],
                              onTap: () async {
                                final picked = await _pickFromSearchSheet(
                                  title: 'Выберите категорию',
                                  items: st.categories
                                      .map((c) => (c.id, c.name))
                                      .toList(),
                                  selectedId: effectiveCategoryId,
                                );
                                if (picked == null) return;
                                await ctrl.selectCategory(picked);
                                _clearField(_kCategory);
                                _clearField(_kPrayer);
                              },
                            ),

                            const SizedBox(height: 12),
                            const _Label('Молитва'),

                            if (st.prayersLoading)
                              const Padding(
                                padding: EdgeInsets.only(top: 6, bottom: 6),
                                child: LinearProgressIndicator(minHeight: 2),
                              ),

                            _InkField(
                              value: effectiveCategoryId == null
                                  ? '--выберите категорию--'
                                  : (effectivePrayerId == null
                                  ? '--выберите молитву--'
                                  : _resolvePrayerName(
                                st,
                                effectivePrayerId,
                              )),
                              enabled:
                              effectiveCategoryId != null &&
                                  !st.prayersLoading &&
                                  st.prayers.isNotEmpty,
                              error: _errors[_kPrayer],
                              onTap: () async {
                                if (effectiveCategoryId == null) return;

                                final picked = await _pickFromSearchSheet(
                                  title: 'Выберите молитву',
                                  items: st.prayers
                                      .map((p) => (p.id, p.name))
                                      .toList(),
                                  selectedId: effectivePrayerId,
                                );
                                if (picked == null) return;
                                ctrl.selectPrayer(picked);
                                _clearField(_kPrayer);
                              },
                            ),

                            if (canUseSelfPrayer) ...[
                              Row(
                                children: [
                                  Checkbox(
                                    value: st.selfPray,
                                    onChanged: (v) {
                                      ctrl.setSelfPray(v ?? false);
                                      if (!(v ?? false)) _clearField(_kSelfText);
                                    },
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
                                    effectivePrayerText.isEmpty
                                        ? 'Выберите молитву — здесь появится текст'
                                        : effectivePrayerText,
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
                              error: _errors[_kSelfText],
                              onChanged: (_) => _clearField(_kSelfText),
                            ),
                            if (canUseSelfPrayer)
                              Row(
                                children: [
                                  Checkbox(
                                    value: st.selfPray,
                                    onChanged: (v) =>
                                        ctrl.setSelfPray(v ?? false),
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

                    // ✅ Тип/Дата/Семейная молитва — ВЕРНУЛ/ОСТАВИЛ
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RadioListTile<int>(
                            contentPadding: EdgeInsets.zero,
                            value: 1,
                            groupValue: _translationType,
                            onChanged: (v) =>
                                setState(() => _translationType = v ?? 1),
                            title: const Text('Открытая молитва'),
                            activeColor: Colors.black87,
                          ),
                          RadioListTile<int>(
                            contentPadding: EdgeInsets.zero,
                            value: 2,
                            groupValue: _translationType,
                            onChanged: (v) =>
                                setState(() => _translationType = v ?? 2),
                            title: const Text('Закрытая молитва'),
                            activeColor: Colors.black87,
                          ),
                          // RadioListTile<int>(
                          //   contentPadding: EdgeInsets.zero,
                          //   value: 3,
                          //   groupValue: _translationType,
                          //   onChanged: (v) =>
                          //       setState(() => _translationType = v ?? 3),
                          //   title: const Text('Семейная молитва'),
                          //   activeColor: Colors.black87,
                          // ),
                          const SizedBox(height: 8),

                          _DateTimeField(
                            value: _dateTime,
                            error: _errors[_kDateTime],
                            onPick: _pickDateTime,
                            onClear: () => setState(() => _dateTime = null),
                          ),

                          const SizedBox(height: 10),
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
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: st.isSubmitting
                          ? null
                          : () async {
                        if (!_validateAndShow(st)) return;

                        try {
                          if (_isSos) {
                            await ctrl.submitSos(
                              description: _descCtrl.text.trim(),
                              categoryId: st.categoryId!,
                            );

                            if (!mounted) return;

                            setState(() {
                              _descCtrl.clear();
                              _isSos = false;
                              _errors.clear();
                            });

                            final bool target = ProfileRole.layman == st.role;

                            print(target);
                            print(st.role);

                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => StreamsScreen(
                                  my: true,
                                  initialStatus: target ? StreamStatus.planned : StreamStatus.active,
                                ),
                              ),
                            );
                            return;
                          }

                          await ctrl.submitTranslation(
                            name: _nameCtrl.text.trim(),
                            description: _descCtrl.text.trim(),
                            type: _isSos ? 4 : _translationType,
                            datePlanned: _dateTime!,
                            selfPray: st.selfPray,
                            selfPrayText: _selfPrayText.text.trim(),
                          );

                          if (!mounted) return;

                          // ✅ решаем, какой таб открыть в "Мои трансляции"
                          final now = DateTime.now();
                          final planned = _dateTime!;
                          final targetStatus =
                          planned.isAfter(
                            now.add(const Duration(seconds: 30)),
                          )
                              ? StreamStatus.planned
                              : StreamStatus.active;

                          // ✅ перенаправляем в "Мои трансляции" и открываем нужный раздел
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => StreamsScreen(
                                my: true,
                                initialStatus: targetStatus,
                              ),
                            ),
                          );
                        } catch (_) {
                          // ошибки уже покажутся через ref.listen(errorMessage)
                        }
                      },
                      child: st.isSubmitting
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Text(_isSos ? 'Отправить SOS' : 'Создать заявку'),
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
  final String? error;

  const _TextArea({
    required this.controller,
    required this.rows,
    this.onChanged,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = error != null && error!.isNotEmpty;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLines: rows,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: hasError ? Colors.red : Colors.black26),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: hasError ? Colors.red : Colors.black45),
        ),
      ),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  final DateTime? value;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final String? error;

  const _DateTimeField({
    required this.value,
    required this.onPick,
    required this.onClear,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = error != null && error!.isNotEmpty;

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
          border: Border.all(color: hasError ? Colors.red : Colors.black26),
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
  final String? error;

  const _InkField({
    required this.value,
    required this.enabled,
    required this.onTap,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = error != null && error!.isNotEmpty;

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
          border: Border.all(color: hasError ? Colors.red : Colors.black26),
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
