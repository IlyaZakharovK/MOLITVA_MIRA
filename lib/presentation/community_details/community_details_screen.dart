import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/community_details/community_details.dart';
import '../../helper/image_helper.dart';
import '../shell/app_shell.dart';
import '../widgets/app_message_bar.dart';
import '../widgets/top_bar.dart';
import 'community_details_controller.dart';

class CommunityDetailsScreen extends ConsumerStatefulWidget {
  static const routeName = '/community_details';

  final int communityID;
  final String invite;
  final bool invited;

  const CommunityDetailsScreen({
    super.key,
    required this.communityID,
    this.invite = '',
    this.invited = false,
  });

  @override
  ConsumerState<CommunityDetailsScreen> createState() =>
      _CommunityDetailsScreenState();
}

class _CommunityDetailsScreenState
    extends ConsumerState<CommunityDetailsScreen> {
  late final ScrollController _scroll;

  bool _uploadingLogo = false;

  int _logoBust = DateTime.now().millisecondsSinceEpoch;

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

  Future<void> _hardImageRefresh() async {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    setState(() => _logoBust = DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _onRefresh() async {
    await _hardImageRefresh();
    await ref.read(communityDetailsControllerProvider(_args).notifier).refresh();
  }

  Future<void> _onPickLogo(Group group) async {
    if (!group.isOwner) return;
    if (_uploadingLogo) return;

    final bytes = await pickImageBytes(context);
    if (bytes == null) return;

    setState(() => _uploadingLogo = true);
    try {
      final res = await ref
          .read(communityDetailsControllerProvider(_args).notifier)
          .uploadCommunityLogo(bytes);

      await _hardImageRefresh();
      await ref
          .read(communityDetailsControllerProvider(_args).notifier)
          .refresh();

      final status = (res['status'] ?? '').toString();
      final desc = (res['description'] ?? '').toString();
      showAppMessageBar(
        context,
        status.isEmpty ? 'Иконка сообщества обновлена' : desc,
        brand: Colors.greenAccent,
      );
    } catch (e) {
      showAppMessageBar(
        context,
        'Ошибка загрузки иконки: $e',
        brand: Colors.redAccent,
      );
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  Future<void> _openCreatePostSheet(BuildContext context) async {
    final res = await showModalBottomSheet<_CreatePostResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreatePostSheet(rootContext: context),
    );

    if (res == null) return;

    try {
      await ref
          .read(communityDetailsControllerProvider(_args).notifier)
          .createPost(title: res.title, message: res.message);

      if (context.mounted) {
        showAppMessageBar(context, 'Пост добавлен');
      }
    } catch (e) {
      if (context.mounted) {
        showAppMessageBar(
          context,
          'Ошибка: $e',
          brand: Colors.redAccent,
        );
      }
    }
  }

  Future<void> _onInvite(BuildContext context, Group gp) async {
    final inviteType = gp.isClose && (gp.invite != '');
    final link = inviteType
        ? 'https://molitvamira.ru/groups/?invite=${Uri.encodeComponent(gp.invite)}'
        : 'https://molitvamira.ru/groups/?id=${Uri.encodeComponent(gp.id.toString())}';
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

  Future<void> _onToggleComments(Group group) async {
    if (!group.isOwner) return;

    try {
      await ref
          .read(communityDetailsControllerProvider(_args).notifier)
          .setCommentsStatus();

      if (!mounted) return;
      showAppMessageBar(
        context,
        group.allowComments
            ? 'Комментарии запрещены'
            : 'Комментарии разрешены',
      );
    } catch (e) {
      if (!mounted) return;
      showAppMessageBar(
        context,
        'Ошибка: $e',
        brand: Colors.redAccent,
      );
    }
  }

  Future<void> _onDeleteComment({
    required int postId,
    required int commentId,
  }) async {
    try {
      await ref
          .read(communityDetailsControllerProvider(_args).notifier)
          .deleteComment(postId: postId, commentId: commentId);

      if (!mounted) return;
      showAppMessageBar(context, 'Комментарий удалён');
    } catch (e) {
      if (!mounted) return;
      showAppMessageBar(
        context,
        'Ошибка: $e',
        brand: Colors.redAccent,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(communityDetailsControllerProvider(_args));

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
                  onRefresh: _onRefresh,
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
                                logoBust: _logoBust,
                                logoUploading: _uploadingLogo,
                                isSubBusy: st.isSubBusy,
                                onToggleSubscribe: () => ref
                                    .read(
                                  communityDetailsControllerProvider(
                                    _args,
                                  ).notifier,
                                )
                                    .toggleSubscribe(),
                                onEditLogo: st.group.isOwner
                                    ? () => _onPickLogo(st.group)
                                    : null,
                                onCreatePost: st.group.isOwner
                                    ? () => _openCreatePostSheet(context)
                                    : null,
                                onInvite: () => _onInvite(context, st.group),
                                onToggleComments: st.group.isOwner
                                    ? () => _onToggleComments(st.group)
                                    : null,
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
                                  .read(
                                communityDetailsControllerProvider(
                                  _args,
                                ).notifier,
                              )
                                  .createComment(postId: postId, message: text),
                              onDeleteComment: _onDeleteComment,
                              subed: st.group.isSubscribed,
                              allowComments: st.group.allowComments,
                              isOwner: st.group.isOwner,
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
  static const _red = Color(0xFFD9534F);

  final Group group;
  final int logoBust;
  final bool logoUploading;
  final bool isSubBusy;
  final VoidCallback onToggleSubscribe;
  final VoidCallback? onCreatePost;
  final VoidCallback? onEditLogo;
  final VoidCallback? onInvite;
  final Future<void> Function()? onToggleComments;

  const _CommunityHeader({
    required this.group,
    required this.logoBust,
    required this.logoUploading,
    required this.isSubBusy,
    required this.onToggleSubscribe,
    required this.onCreatePost,
    this.onEditLogo,
    this.onInvite,
    this.onToggleComments,
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
          isSubBusy ? '...' : (subscribed ? 'Вы подписаны' : 'Подписаться'),
          style: const TextStyle(fontSize: 11),
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
        child: const Text('Добавить пост', style: TextStyle(fontSize: 11), textAlign: TextAlign.center,),
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
        child: const Text('Пригласить', style: TextStyle(fontSize: 11)),
      ),
    );

    Widget commentsButton() => SizedBox(
      height: 45,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: group.allowComments ? _green : _red,
          side: BorderSide(
            color: group.allowComments ? _green : _red,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onToggleComments,
        child: Text(
          group.allowComments
              ? 'Комментарии разрешены'
              : 'Комментарии запрещены',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ),
    );

    final btns = <Widget>[
      subButton(),
      if (onCreatePost != null) createPostButton(),
      inviteButton(),
      commentsButton(),
    ];

    Widget buttonsLayout() {
      const gap = 10.0;

      final rows = <Widget>[];
      for (var i = 0; i < btns.length; i += 2) {
        final left = btns[i];
        final right = i + 1 < btns.length ? btns[i + 1] : null;

        rows.add(
          Row(
            children: [
              Expanded(child: left),
              if (right != null) ...[
                const SizedBox(width: gap),
                Expanded(child: right),
              ] else ...[
                const SizedBox(width: gap),
                const Expanded(child: SizedBox.shrink()),
              ],
            ],
          ),
        );
      }

      return Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: gap),
            rows[i],
          ],
        ],
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
              _SquareAvatar(
                url: group.logoUrl,
                bust: logoBust,
                canEdit: onEditLogo != null,
                uploading: logoUploading,
                onTapCamera: onEditLogo,
              ),
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
                        const Icon(
                          Icons.person_outline,
                          size: 18,
                          color: Colors.black45,
                        ),
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
                        const Icon(
                          Icons.people_alt_outlined,
                          size: 18,
                          color: Colors.black38,
                        ),
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
  final int bust;
  final bool canEdit;
  final bool uploading;
  final VoidCallback? onTapCamera;

  const _SquareAvatar({
    required this.url,
    required this.bust,
    required this.canEdit,
    required this.uploading,
    required this.onTapCamera,
  });

  @override
  Widget build(BuildContext context) {
    final raw = url.trim();
    final has = raw.isNotEmpty;

    final displayUrl = !has
        ? ''
        : (raw.contains('?') ? '$raw&v=$bust' : '$raw?v=$bust');

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 82,
            height: 82,
            color: const Color(0xFFF0F2F4),
            alignment: Alignment.center,
            child: has
                ? Image.network(
              displayUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.group_outlined,
                size: 40,
                color: Colors.black38,
              ),
            )
                : const Icon(
              Icons.group_outlined,
              size: 40,
              color: Colors.black38,
            ),
          ),
        ),
        if (canEdit)
          Positioned(
            right: -2,
            bottom: -2,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: uploading ? null : onTapCamera,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: uploading
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.photo_camera, size: 18),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PostCard extends StatefulWidget {
  final Post post;
  final int? myUserId;
  final String? myUserName;
  final bool subed;
  final bool allowComments;
  final bool isOwner;
  final Future<void> Function(int postId, String text) onSendComment;
  final Future<void> Function({
  required int postId,
  required int commentId,
  }) onDeleteComment;

  const _PostCard({
    required this.post,
    required this.myUserId,
    required this.myUserName,
    required this.onSendComment,
    required this.onDeleteComment,
    required this.subed,
    required this.allowComments,
    required this.isOwner,
  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _commentsExpanded = false;
  late final TextEditingController _commentCtrl;
  bool _sending = false;
  int? _deletingCommentId;

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
      return myName;
    }
    return serverName;
  }

  int _commentId(Comment c) {
    final dynamic dc = c;

    try {
      final raw = dc.commentId;
      if (raw is int) return raw;
      final parsed = int.tryParse(raw.toString());
      if (parsed != null) return parsed;
    } catch (_) {}

    try {
      final raw = dc.id;
      if (raw is int) return raw;
      final parsed = int.tryParse(raw.toString());
      if (parsed != null) return parsed;
    } catch (_) {}

    return 0;
  }

  Future<void> _onDeleteComment(int postId, Comment c) async {
    final commentId = _commentId(c);
    if (commentId == 0) {
      showAppMessageBar(
        context,
        'Не удалось определить комментарий для удаления',
        brand: Colors.redAccent,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить комментарий?'),
        content: const Text(
          'Комментарий будет удалён без возможности восстановления.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    ) ??
        false;

    if (!confirmed) return;

    setState(() => _deletingCommentId = commentId);
    try {
      await widget.onDeleteComment(postId: postId, commentId: commentId);
    } finally {
      if (mounted) setState(() => _deletingCommentId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final dateLabel = post.dateAdd;
    final author = _authorName(post.userId, post.userName);
    final postId = post.postId != 0 ? post.postId : post.id;
    final comments = post.comments;
    final showToggleComments = comments.length > 3;
    final canWriteComments = widget.subed && widget.allowComments;

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
                const Icon(Icons.person_outlined, color: Colors.grey),
                const SizedBox(width: 5),
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
            if (visibleComments.isNotEmpty) ...[
              for (final c in visibleComments) ...[
                _CommentTile(
                  c: c,
                  canDelete: widget.isOwner,
                  deleting: _deletingCommentId == _commentId(c),
                  onDelete: widget.isOwner ? () => _onDeleteComment(postId, c) : null,
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
            if (canWriteComments) ...[
              TextField(
                controller: _commentCtrl,
                decoration: const InputDecoration(
                  hintText: 'Написать комментарий…',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
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
                    if (text.isEmpty) {
                      showAppMessageBar(
                        context,
                        'Введите текст комментария',
                        brand: Colors.redAccent,
                      );
                      return;
                    }

                    setState(() => _sending = true);
                    try {
                      await widget.onSendComment(postId, text);
                      _commentCtrl.clear();
                      if (mounted) {
                        showAppMessageBar(context, 'Комментарий добавлен');
                      }
                    } catch (e) {
                      if (mounted) {
                        showAppMessageBar(
                          context,
                          'Ошибка: $e',
                          brand: Colors.redAccent,
                        );
                      }
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
            ] else if (!widget.allowComments) ...[
              _CommentsDisabledHint(isOwner: widget.isOwner),
            ] else ...[
              _NoSubscribeCommentsHint(),
            ],
          ],
        ),
      ),
    );
  }
}

class _NoSubscribeCommentsHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x22000000)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, size: 18, color: Colors.black45),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Комментировать могут только подписчики сообщества.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentsDisabledHint extends StatelessWidget {
  final bool isOwner;

  const _CommentsDisabledHint({required this.isOwner});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x22000000)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.comments_disabled_outlined,
            size: 18,
            color: Colors.black45,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isOwner
                  ? 'Комментарии в сообществе сейчас запрещены. Вы можете снова разрешить их кнопкой в заголовке сообщества.'
                  : 'Комментарии в этом сообществе сейчас запрещены владельцем.',
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment c;
  final bool canDelete;
  final bool deleting;
  final VoidCallback? onDelete;

  const _CommentTile({
    required this.c,
    this.canDelete = false,
    this.deleting = false,
    this.onDelete,
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.userName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
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
                      ],
                    ),
                  ),
                  if (canDelete)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      tooltip: 'Удалить комментарий',
                      onPressed: deleting ? null : onDelete,
                      icon: deleting
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Colors.black45,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
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
              overflow:
              _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
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

class _CreatePostResult {
  final String title;
  final String message;

  const _CreatePostResult({required this.title, required this.message});
}

class _CreatePostSheet extends StatefulWidget {
  final BuildContext rootContext;

  const _CreatePostSheet({required this.rootContext});

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
      showAppMessageBar(
        widget.rootContext,
        'Заполните заголовок и текст',
        brand: Colors.redAccent,
      );
      return;
    }

    Navigator.of(
      context,
    ).pop(_CreatePostResult(title: title, message: message));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
