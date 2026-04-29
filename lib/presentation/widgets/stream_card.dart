import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/streams/stream_type.dart';
import '../../domain/streams/streams_item.dart';
import '../../helper/image_helper.dart';
import '../streams/streams_controller.dart';

import 'app_message_bar.dart';

import 'package:vsem_mirom/domain/streams/stream_status.dart';
import 'package:vsem_mirom/domain/streams/stream_status_id.dart';

import 'audio_player.dart';

final _likeBusyProvider = StateProvider.family<bool, String>(
      (ref, id) => false,
);

final _avatarBusyProvider = StateProvider.family<bool, String>(
      (ref, id) => false,
);

class StreamCard extends ConsumerWidget {
  final StreamItem item;
  final bool my;
  final StreamStatus status;

  const StreamCard({
    super.key,
    required this.item,
    required this.my,
    required this.status,
  });

  static const _blue = Color(0xFF2F66FF);

  String _fmt(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year} / ${two(dt.hour)}:${two(dt.minute)}';
  }

  Color _statusBg(StreamStatusID s) {
    switch (s) {
      case StreamStatusID.moderated:
        return const Color(0xFFFFC107);
      case StreamStatusID.blessed:
        return const Color(0xFF1B8F2E);
      case StreamStatusID.blocked:
      case StreamStatusID.deleted:
        return const Color(0xFFE53935);
      case StreamStatusID.nodata:
      default:
        return const Color(0xFFE0E0E0);
    }
  }

  Color _statusTextColor(StreamStatusID s) {
    switch (s) {
      case StreamStatusID.moderated:
        return const Color(0xFF6A4F00);
      case StreamStatusID.nodata:
        return Colors.black54;
      default:
        return Colors.white;
    }
  }

  void _onOpen(BuildContext context) {
    switch (item.statusId) {
      case StreamStatusID.blocked:
        showAppMessageBar(context, 'Трансляция заблокирована');
        return;
      case StreamStatusID.deleted:
        showAppMessageBar(context, 'Трансляция удалена пользователем');
        return;
      case StreamStatusID.nodata:
        showAppMessageBar(context, 'Нет данных о статусе трансляции');
        return;
      case StreamStatusID.moderated:
        showAppMessageBar(context, 'Трансляция на модерации');
        return;
      case StreamStatusID.blessed:
        break;
    }

    if (status != StreamStatus.active) {
      if (status == StreamStatus.planned) {
        showAppMessageBar(context, 'Трансляция ещё не началась');
      } else {
        showAppMessageBar(context, 'Трансляция завершена');
      }
      return;
    }

    Navigator.of(context).pushReplacementNamed(
      '/live_stream',
      arguments: {'translationID': item.id, 'invited': false},
    );
  }

  Future<void> _onShareInvite(BuildContext context) async {
    final invite = item.invite.isEmpty
        ? item.id.toString().trim()
        : item.invite.toString().trim();
    debugPrint(invite);
    if (invite.isEmpty) {
      showAppMessageBar(
        context,
        'Нет кода приглашения',
        brand: Colors.redAccent,
      );
      return;
    }

    final link = item.invite.isEmpty
        ? 'https://molitvamira.ru/translations/?id=${Uri.encodeComponent(invite)}'
        : 'https://molitvamira.ru/translations/?invite=${Uri.encodeComponent(invite)}';
    await Clipboard.setData(ClipboardData(text: link));

    await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Приглашение'),
        content: const Text(
          'Пригласительная ссылка скопирована в буфер. Теперь Вы можете ее отправить другому участнику.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPrayerTextDialog(BuildContext context) async {
    final prayText = item.prayText.trim();
    if (prayText.isEmpty) {
      showAppMessageBar(context, 'Текст молитвы отсутствует');
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Text(
                        'Текст молитвы',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4A4F57),
                        ),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.of(ctx).pop(),
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(
                          Icons.close,
                          size: 24,
                          color: Color(0xFF7A7F87),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      prayText,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF34373D),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    height: 36,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF495D9B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Закрыть'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liked = item.isLiked;
    final busy = ref.watch(_likeBusyProvider(item.id));
    final likesCount = item.likes;

    final canShareInvite =
        (status == StreamStatus.active || status == StreamStatus.planned) && my;

    final isPlanned = status == StreamStatus.planned;
    final isCompleted = status != StreamStatus.active && !isPlanned;
    final dateToShow = isCompleted ? item.endAt : item.startAt;

    final bool isSos = item.typeId == StreamType.sos;
    final bool isModeration = item.statusId == StreamStatusID.moderated;
    final bool showPlannedPrayerRow = status == StreamStatus.planned;

    Future<void> onLikeToggle() async {
      if (busy) return;

      ref.read(_likeBusyProvider(item.id).notifier).state = true;
      try {
        await ref
            .read(streamsControllerProvider((my: my, status: status)).notifier)
            .likeTranslation(item.id);
      } catch (e) {
        showAppMessageBar(context, e.toString());
      } finally {
        ref.read(_likeBusyProvider(item.id).notifier).state = false;
      }
    }

    final avatarBusy = ref.watch(_avatarBusyProvider(item.id));
    final canEditAvatar =
        my && (status == StreamStatus.active || status == StreamStatus.planned);

    Future<void> _onListenAudio(BuildContext context) async {
      if (!item.saveMediaTranslation ||
          item.saveMediaTranslationUrl == '0' ||
          !my) {
        return;
      }

      final url = item.saveMediaTranslationUrl;
      if (url.isEmpty) {
        showAppMessageBar(context, 'Ссылка на аудио недоступна');
        return;
      }

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => AudioPlayerWidget(
          url: 'https://media.molitvamira.ru$url',
          onClose: () => Navigator.of(ctx).pop(),
          name: item.title,
          date: item.endAt.toString(),
        ),
      );
    }

    Future<void> onChangeAvatar() async {
      if (!canEditAvatar) return;
      if (avatarBusy) return;

      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Сменить аватарку трансляции?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Вы хотите выбрать новое изображение для этой трансляции?',
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Нет'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Да'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      if (confirmed != true) return;

      final bytes = await pickImageBytes(context);
      if (bytes == null) return;

      ref.read(_avatarBusyProvider(item.id).notifier).state = true;
      try {
        final key = (my: my, status: status);
        final ctrl = ref.read(streamsControllerProvider(key).notifier);

        final res = await ctrl.uploadStreamAvatar(
          streamId: item.id,
          bytes: bytes,
        );

        final statusText = (res['status'] ?? '').toString();
        final desc = (res['description'] ?? '').toString();

        showAppMessageBar(
          context,
          statusText.isEmpty ? 'Аватар трансляции обновлён' : desc,
          brand: Colors.greenAccent,
        );
      } catch (e) {
        showAppMessageBar(
          context,
          'Ошибка загрузки: $e',
          brand: Colors.redAccent,
        );
      } finally {
        ref.read(_avatarBusyProvider(item.id).notifier).state = false;
      }
    }

    Widget actionPill() {
      if (isSos && isModeration && !isCompleted) {
        return const _WaitingModerationPill();
      }

      if (!isSos && status == StreamStatus.planned) {
        return _CountdownPill(target: item.startAt);
      }

      if (status == StreamStatus.blocked) {
        return Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: const Color(0xFFE9ECEF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Заблокирована',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.black45,
            ),
          ),
        );
      }

      if (status == StreamStatus.finished) {
        return Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: const Color(0xFFE9ECEF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Завершена',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.black45,
            ),
          ),
        );
      }

      if (status == StreamStatus.active) {
        return SizedBox(
          height: 32,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            onPressed: () => _onOpen(context),
            child: const Text('Войти'),
          ),
        );
      }

      return Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: const Color(0xFFE9ECEF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Завершена',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.black45,
          ),
        ),
      );
    }

    Widget prayerActionRow() {
      return Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: busy ? null : onLikeToggle,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: liked ? const Color(0xFF2F66FF) : const Color(0xFFD9DFEA),
                  ),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Буду молиться',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: busy
                              ? Colors.black38
                              : (liked ? const Color(0xFF2F66FF) : Colors.black87),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      liked
                          ? Icons.volunteer_activism
                          : Icons.volunteer_activism_outlined,
                      size: 18,
                      color: busy
                          ? Colors.black38
                          : (liked ? const Color(0xFF2F66FF) : Colors.black87),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      likesCount.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: busy
                            ? Colors.black38
                            : (liked ? const Color(0xFF2F66FF) : Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _showPrayerTextDialog(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.greenAccent),
              ),
              child: const Icon(
                Icons.menu_book_outlined,
                size: 18,
                color: Colors.greenAccent,
              ),
            ),
          ),
        ],
      );
    }

    Widget regularActionsRow() {
      return Row(
        children: [
          if (status == StreamStatus.active || status == StreamStatus.planned) ...[
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: actionPill(),
              ),
            ),
            const SizedBox(width: 10),
          ] else ...[
            Align(
              alignment: Alignment.centerLeft,
              child: actionPill(),
            ),
          ],
          if (status == StreamStatus.active) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 52),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person,
                      size: 18,
                      color: Colors.black26,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.participants.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (status == StreamStatus.planned) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 52),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: busy ? null : onLikeToggle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        liked
                            ? Icons.volunteer_activism
                            : Icons.volunteer_activism_outlined,
                        size: 18,
                        color: busy
                            ? Colors.black26
                            : (liked ? Colors.orange : Colors.black26),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        likesCount.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const Spacer(),
          if (status == StreamStatus.finished &&
              item.saveMediaTranslation &&
              item.saveMediaTranslationUrl != '0' &&
              my) ...[
            InkWell(
              onTap: () => _onListenAudio(context),
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: Colors.greenAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.headphones_outlined,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _showPrayerTextDialog(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.greenAccent),
              ),
              child: const Icon(
                Icons.menu_book_outlined,
                size: 18,
                color: Colors.greenAccent,
              ),
            ),
          ),
        ],
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _onOpen(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              blurRadius: 18,
              color: Color(0x14000000),
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Material(
                    color: const Color(0xFFEDEDED),
                    child: InkWell(
                      onTap: canEditAvatar ? onChangeAvatar : null,
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (item.image.isNotEmpty)
                              Image.network(
                                item.image,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.groups,
                                  size: 40,
                                  color: Colors.black38,
                                ),
                              )
                            else
                              const Icon(
                                Icons.groups,
                                size: 40,
                                color: Colors.black38,
                              ),
                            if (canEditAvatar)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0xB3000000),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: avatarBusy
                                      ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                      : const Icon(
                                    Icons.photo_camera,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description.isEmpty ? 'Без описания' : item.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black45,
                        ),
                      ),
                      const SizedBox(height: 10),
                      showPlannedPrayerRow ? prayerActionRow() : regularActionsRow(),
                    ],
                  ),
                ),
              ],
            ),
            if (showPlannedPrayerRow) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: actionPill(),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.black38),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Дата: ${_fmt(dateToShow)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (canShareInvite) ...[
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _onShareInvite(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9ECEF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.share,
                        size: 18,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusBg(item.statusId),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item.statusId == StreamStatusID.moderated
                        ? 'На модерации'
                        : item.statusId.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: _statusTextColor(item.statusId),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WaitingModerationPill extends StatelessWidget {
  const _WaitingModerationPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: const Color(0xFFE9ECEF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Ожидает модерации',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Colors.black38,
        ),
      ),
    );
  }
}

class _CountdownPill extends StatefulWidget {
  final DateTime target;

  const _CountdownPill({required this.target});

  @override
  State<_CountdownPill> createState() => _CountdownPillState();
}

class _CountdownPillState extends State<_CountdownPill> {
  Timer? _t;
  late Duration _left;

  @override
  void initState() {
    super.initState();
    _left = widget.target.difference(DateTime.now());
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      final d = widget.target.difference(DateTime.now());
      if (!mounted) return;
      setState(() => _left = d);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  String _fmtLeft(Duration d) {
    if (d.isNegative) d = Duration.zero;
    final days = d.inDays;
    final hours = d.inHours.remainder(24);
    final mins = d.inMinutes.remainder(60);
    final secs = d.inSeconds.remainder(60);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${days}дн. ${two(hours)}ч:${two(mins)}м:${two(secs)}с';
  }

  @override
  Widget build(BuildContext context) {
    final left = _left;
    final txt = _fmtLeft(left);

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: const Color(0xFF2F66FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        txt,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}
