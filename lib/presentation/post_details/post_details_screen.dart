import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shell/app_shell.dart';
import '../widgets/top_bar.dart';
import '../../domain/post_details/post_comment.dart';
import 'post_details_controller.dart';

class PostDetailsScreen extends ConsumerStatefulWidget {
  static const routeName = '/post_details';

  final String postId;
  const PostDetailsScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends ConsumerState<PostDetailsScreen> {
  final _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(postDetailsControllerProvider(widget.postId));

    return AppShell(
      child: SafeArea(
        child: Column(
          children: [
            const TopBar(title: 'Пост'),

            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Ошибка: $e')),
                data: (state) => RefreshIndicator(
                  onRefresh: () => ref
                      .read(postDetailsControllerProvider(widget.postId).notifier)
                      .refresh(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    children: [
                      _PostCard(
                        author: state.post.author,
                        timeLabel: state.post.timeLabel,
                        text: state.post.text,
                        hasImage: state.post.hasImage,
                        likes: state.post.likes,
                        onLike: () => ref
                            .read(postDetailsControllerProvider(widget.postId).notifier)
                            .likeOnce(),
                      ),
                      const SizedBox(height: 14),

                      // Заголовок "Комментарии"
                      Text(
                        'Комментарии',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Список комментариев
                      ...state.comments.map((c) => _CommentBubble(c: c)),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),

            // Поле ввода комментария (внизу)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentCtrl,
                        decoration: InputDecoration(
                          hintText: 'Написать комментарий...',
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.black12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF3F4F86)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 42,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF3F4F86),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final text = _commentCtrl.text;
                          _commentCtrl.clear();
                          await ref
                              .read(postDetailsControllerProvider(widget.postId).notifier)
                              .addComment(text);
                        },
                        child: const Icon(Icons.send, size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final String author;
  final String timeLabel;
  final String text;
  final bool hasImage;
  final int likes;
  final VoidCallback onLike;

  const _PostCard({
    required this.author,
    required this.timeLabel,
    required this.text,
    required this.hasImage,
    required this.likes,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                const CircleAvatar(radius: 18, backgroundColor: Color(0xFF3F4F86)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(author,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          )),
                      const SizedBox(height: 2),
                      Text(timeLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.black45,
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black45,
                height: 1.35,
              ),
            ),
          ),
          if (hasImage)
            Container(
              height: 220,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              decoration: BoxDecoration(
                color: const Color(0xFF3F4F86),
                borderRadius: BorderRadius.circular(12),
              ),
            ),

          // ✅ тут оставляем только лайк и шаринг (без комментов и их числа)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                InkWell(
                  onTap: onLike,
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.thumb_up, size: 18, color: Color(0xFF3F4F86)),
                  ),
                ),
                const SizedBox(width: 6),
                Text('$likes',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.share, size: 18, color: Color(0xFF3F4F86),),
                  label: const Text('Поделиться', style: TextStyle(color: Color(0xFF3F4F86)),),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentBubble extends StatelessWidget {
  final PostComment c;
  const _CommentBubble({required this.c});

  @override
  Widget build(BuildContext context) {
    final isMine = c.isMine;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isMine ? const Color(0xFF3F4F86) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 12,
                  color: Color(0x12000000),
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMine)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      c.author,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                Text(
                  c.text,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isMine ? Colors.white : Colors.black87,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
