import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/community_details/community_details.dart';
import '../shell/app_shell.dart';
import '../widgets/top_bar.dart';
import 'community_details_controller.dart';

class CommunityDetailsScreen extends ConsumerStatefulWidget {
  static const routeName = '/community_details';

  final int communityID;
  final String invite;
  final bool invited;
  const CommunityDetailsScreen({super.key, required this.communityID, this.invite = '', this.invited = false});

  @override
  ConsumerState<CommunityDetailsScreen> createState() =>
      _CommunityDetailsScreenState();
}

class _CommunityDetailsScreenState extends ConsumerState<CommunityDetailsScreen> {
  late final ScrollController _scroll;
  CommunityDetailsArgs get _args => (
  groupId: widget.communityID,
  invited: widget.invited,
  invite: widget.invite,
  );

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final p = _scroll.position;
    if (p.pixels >= p.maxScrollExtent - 320) {
      ref
          .read(communityDetailsControllerProvider(_args).notifier)
          .loadMore()
          .catchError((_) {});
    }
  }

  Future<void> _openCreatePostSheet(BuildContext context) async {
    final res = await showModalBottomSheet<_CreatePostResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreatePostSheet(),
    );

    if (res == null) return;

    try {
      await ref
          .read(communityDetailsControllerProvider(_args).notifier)
          .createPost(title: res.title, message: res.message);

      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Пост добавлен')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  Future<void> _onInvite(BuildContext context, Group gp) async {
    final inviteType = gp.isClose && (gp.invite != "");
    final link = inviteType ?
    'https://molitvamira.ru/groups/?invite=${Uri.encodeComponent(gp.invite)}':
    'https://molitvamira.ru/groups/?id=${Uri.encodeComponent(gp.id.toString())}';
    await Clipboard.setData(ClipboardData(text: link));

    await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Приглашение'),
        content: const Text('Пригласительная ссылка скопирована в буфер. Теперь Вы можете ее отправить другому участнику.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async =
    ref.watch(communityDetailsControllerProvider(_args));

    return AppShell(
      child: SafeArea(
        child: Column(
          children: [
            const TopBar(title: 'Сообщество'),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Ошибка: $e')),
                data: (st) => RefreshIndicator(
                  onRefresh: () => ref
                      .read(communityDetailsControllerProvider(_args)
                      .notifier)
                      .refresh(),
                  child: Stack(
                    children: [
                      ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: 1 + st.posts.length,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _CommunityHeader(
                                group: st.group,
                                isSubBusy: st.isSubBusy,
                                onToggleSubscribe: () => ref
                                    .read(communityDetailsControllerProvider(
                                    _args)
                                    .notifier)
                                    .toggleSubscribe(),
                                onCreatePost: st.group.isOwner
                                    ? () => _openCreatePostSheet(context)
                                    : null,
                                onInvite: () => _onInvite(context, st.group),
                              ),
                            );
                          }

                          final post = st.posts[index - 1];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _PostCard(
                              post: post,
                              myUserId: st.currentUserId,
                              myUserName: st.group.ownerName,
                              onSendComment: (postId, text) => ref
                                  .read(communityDetailsControllerProvider(
                                  _args)
                                  .notifier)
                                  .createComment(postId: postId, message: text),
                            ),
                          );
                        },
                      ),
                      if (st.isLoadingMore)
                        const Positioned(
                          left: 0,
                          right: 0,
                          bottom: 10,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityHeader extends StatelessWidget {
  static const _blue = Color(0xFF3F4F86);
  static const _green = Color(0xFF0AB39C);

  final Group group;
  final bool isSubBusy;
  final VoidCallback onToggleSubscribe;
  final VoidCallback? onCreatePost;

  /// Третья кнопка (например "Пригласить").
  /// Если тебе нужно оставить заглушкой — можно не передавать и будет NO-OP.
  final VoidCallback? onInvite;

  const _CommunityHeader({
    required this.group,
    required this.isSubBusy,
    required this.onToggleSubscribe,
    required this.onCreatePost,
    this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    final subscribed = group.isSubscribed;

    Widget subButton() => SizedBox(
      height: 45,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: subscribed ? _green : _blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: isSubBusy ? null : onToggleSubscribe,
        child: Text(
          isSubBusy
              ? '...'
              : (subscribed ? 'Вы подписаны' : 'Подписаться'),
          style: TextStyle(
            fontSize: 12
          ),
        ),
      ),
    );

    Widget createPostButton() => SizedBox(
      height: 45,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: _blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onCreatePost,
        child: const Text('Добавить пост', style: TextStyle(fontSize: 12),),
      ),
    );

    Widget inviteButton() => SizedBox(
      height: 45,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: _green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onInvite ??
                () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Приглашение — позже')),
              );
            },
        child: const Text('Пригласить', style: TextStyle(fontSize: 12), ),
      ),
    );

    // Динамически собираем список кнопок (2 или 3)
    final btns = <Widget>[
      subButton(),
      if (onCreatePost != null) createPostButton(),
      inviteButton(),
    ];

    Widget buttonsLayout() {
      const gap = 10.0;

      return LayoutBuilder(
        builder: (context, constraints) {
          if (btns.length == 2) {
            return Row(
              children: [
                Expanded(child: btns[0]),
                const SizedBox(width: gap),
                Expanded(child: btns[1]),
              ],
            );
          }
          final oneRow = constraints.maxWidth >= 360;

          if (oneRow) {
            return Row(
              children: [
                Expanded(child: btns[0]),
                const SizedBox(width: gap),
                Expanded(child: btns[1]),
                const SizedBox(width: gap),
                Expanded(child: btns[2]),
              ],
            );
          }

          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: btns[0]),
                  const SizedBox(width: gap),
                  Expanded(child: btns[1]),
                ],
              ),
              const SizedBox(height: gap),
              Row(
                children: [
                  const Spacer(),
                  Expanded(child: btns[2]),
                ],
              ),
            ],
          );
        },
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 20,
            color: Color(0x14000000),
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SquareAvatar(url: group.logoUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      group.description,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 18, color: Colors.black45),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Основатель: ${group.ownerName}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Colors.black54,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.people_alt_outlined,
                            size: 18, color: Colors.black38),
                        const SizedBox(width: 6),
                        Text(
                          'Подписчиков: ${group.followersCount}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          buttonsLayout(),
        ],
      ),
    );
  }
}
class _SquareAvatar extends StatelessWidget {
  final String url;
  const _SquareAvatar({required this.url});

  @override
  Widget build(BuildContext context) {
    final has = url.trim().isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 82,
        height: 82,
        color: const Color(0xFFF0F2F4),
        alignment: Alignment.center,
        child: has
            ? Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.group_outlined,
              size: 40, color: Colors.black38),
        )
            : const Icon(Icons.group_outlined, size: 40, color: Colors.black38),
      ),
    );
  }
}

class _PostCard extends StatefulWidget {
  final Post post;
  final int? myUserId;
  final String? myUserName;
  final Future<void> Function(int postId, String text) onSendComment;

  const _PostCard({
    required this.post,
    required this.myUserId,
    required this.myUserName,
    required this.onSendComment,
  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _commentsExpanded = false;

  late final TextEditingController _commentCtrl;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _commentCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  String _authorName(int authorId, String serverName) {
    final myId = widget.myUserId;
    final myName = (widget.myUserName ?? '').trim();

    if (myId != null && myId != 0 && authorId == myId && myName.isNotEmpty) {
      return myName; // требование: имя, а не "Вы"
    }
    return serverName;
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    final dateLabel = post.dateAdd;
    final author = _authorName(post.userId, post.userName);

    final postId = post.postId != 0 ? post.postId : post.id;

    final comments = post.comments;
    final showToggleComments = comments.length > 3;

    final visibleComments = _commentsExpanded
        ? comments
        : (comments.length <= 3
        ? comments
        : comments.sublist(comments.length - 3));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 20,
            color: Color(0x14000000),
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFF3F4F86),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Пост: 5 строк + "Показать полностью/Свернуть"
            _SelfExpandableText(
              text: post.message,
              maxLines: 5,
              textStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
                height: 1.35,
              ),
              linkStyle: const TextStyle(
                color: Color(0xFF3F4F86),
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 14),

            // Комментарии (без "фрейма")
            if (visibleComments.isNotEmpty) ...[
              for (final c in visibleComments) ...[
                _CommentTile(
                  c: c,
                  authorName: _authorName(c.userId, c.userName),
                ),
                const SizedBox(height: 12),
              ],
              if (showToggleComments)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () =>
                        setState(() => _commentsExpanded = !_commentsExpanded),
                    child: Text(
                      _commentsExpanded
                          ? 'Свернуть комментарии'
                          : 'Показать все комментарии (${comments.length})',
                      style: const TextStyle(
                        color: Color(0xFF3F4F86),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],

            // Поле ввода во всю ширину + кнопка под ним во всю ширину
            TextField(
              controller: _commentCtrl,
              decoration: const InputDecoration(
                hintText: 'Написать комментарий…',
                isDense: true,
                contentPadding:
                EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3F4F86),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _sending
                    ? null
                    : () async {
                  final text = _commentCtrl.text.trim();
                  if (text.isEmpty) return;

                  setState(() => _sending = true);
                  try {
                    await widget.onSendComment(postId, text);
                    _commentCtrl.clear();
                  } finally {
                    if (mounted) setState(() => _sending = false);
                  }
                },
                child: _sending
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Отправить комментарий'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment c;
  final String authorName;

  const _CommentTile({
    required this.c,
    required this.authorName,
  });

  @override
  Widget build(BuildContext context) {
    final date = _ruDateTime(c.dateAdd);
    final hasAvatar = c.userAvatar.trim().isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFFF0F2F4),
          backgroundImage: hasAvatar ? NetworkImage(c.userAvatar) : null,
          child: hasAvatar
              ? null
              : const Icon(Icons.person, color: Colors.black38),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                authorName,
                style:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                date,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              // Комментарий: обрезка + "Показать полностью/Свернуть"
              _SelfExpandableText(
                text: c.message,
                maxLines: 3,
                textStyle: const TextStyle(
                  fontSize: 12.5,
                  height: 1.3,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                linkStyle: const TextStyle(
                  color: Color(0xFF3F4F86),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Самостоятельно хранит expanded внутри себя — удобно для комментариев.
class _SelfExpandableText extends StatefulWidget {
  final String text;
  final int maxLines;
  final TextStyle textStyle;
  final TextStyle linkStyle;

  const _SelfExpandableText({
    required this.text,
    required this.maxLines,
    required this.textStyle,
    required this.linkStyle,
  });

  @override
  State<_SelfExpandableText> createState() => _SelfExpandableTextState();
}

class _SelfExpandableTextState extends State<_SelfExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.text.trim();
    if (t.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final tp = TextPainter(
          text: TextSpan(text: t, style: widget.textStyle),
          maxLines: widget.maxLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        final overflow = tp.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t,
              style: widget.textStyle,
              maxLines: _expanded ? null : widget.maxLines,
              overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (overflow)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Text(
                    _expanded ? 'Свернуть' : 'Показать полностью',
                    style: widget.linkStyle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/* ===== safe create post sheet ===== */

class _CreatePostResult {
  final String title;
  final String message;
  const _CreatePostResult({required this.title, required this.message});
}

class _CreatePostSheet extends StatefulWidget {
  const _CreatePostSheet();

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _msgCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _msgCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    final message = _msgCtrl.text.trim();

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните заголовок и текст')),
      );
      return;
    }

    Navigator.of(context).pop(_CreatePostResult(title: title, message: message));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Добавить пост',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Заголовок',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _msgCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Текст',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                onPressed: _submit,
                child: const Text('Опубликовать'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ===== date formatter ===== */

String _ruDateTime(DateTime dt) {
  const months = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];
  final d = dt.day.toString().padLeft(2, '0');
  final m = months[(dt.month - 1).clamp(0, 11)];
  final y = dt.year.toString();
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$d $m $y г. $hh:$mm';
}