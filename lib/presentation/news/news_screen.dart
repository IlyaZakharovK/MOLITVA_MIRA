import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vsem_mirom/presentation/widgets/top_bar.dart';
import '../community_details/community_details_screen.dart';
import '../post_details/post_details_screen.dart';
import '../shell/app_shell.dart';

import '../../domain/news/news_item.dart';
import 'news_controller.dart';

class NewsScreen extends ConsumerWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(newsControllerProvider);

    return AppShell(
      child: SafeArea(
        child: Column(
          children: [
            const TopBar(title: 'Совместные молитвы'),

            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Ошибка: $e')),
                data: (posts) => RefreshIndicator(
                  onRefresh: () => ref.read(newsControllerProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: posts.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: NewsPostCard(post: posts[i]),
                    ),
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

class NewsPostCard extends StatelessWidget {
  final NewsPost post;
  const NewsPostCard({super.key, required this.post});

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
                        post.author,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        post.timeLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<int>(
                  icon: const Icon(Icons.more_horiz),
                  color: Colors.white,
                  shadowColor: Color(0xFF3F4F86),
                  onSelected: (v) {
                    if (v == 1) {
                      Navigator.of(context).pushNamed(
                        CommunityDetailsScreen.routeName,
                        arguments: post.author,
                      );
                    }
                    if (v == 2) {
                      Navigator.of(context).pushNamed(
                        PostDetailsScreen.routeName,
                        arguments: post.id,
                      );
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 1,
                      child: Text('Сообщество'),
                    ),
                    PopupMenuItem(
                      value: 2,
                      child: Text('Пост'),
                    ),
                  ],
                ),

              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              post.text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black45,
                height: 1.35,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (post.hasImage)
            Container(
              height: 220,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              decoration: BoxDecoration(
                color: const Color(0xFF3F4F86),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.thumb_up, size: 18, color: Color(0xFF3F4F86)),
                const SizedBox(width: 6),
                Text(
                  '${post.likes}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.chat_bubble_outline, size: 18, color: Color(0xFF3F4F86)),
                const SizedBox(width: 6),
                Text(
                  '${post.comments}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.share, size: 18, color: Color(0xFF3F4F86),),
                  label: const Text('Поделиться', style: TextStyle(color: Color(0xFF3F4F86),),),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
