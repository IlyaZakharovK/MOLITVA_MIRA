import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../post_details/post_details_screen.dart';
import '../shell/app_shell.dart';
import '../widgets/top_bar.dart';
import '../../domain/community_details/community_post.dart';
import 'community_details_controller.dart';

class CommunityDetailsScreen extends ConsumerWidget {
  static const routeName = '/community_details';

  final String communityTitle;
  const CommunityDetailsScreen({super.key, required this.communityTitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(communityDetailsControllerProvider(communityTitle));

    return AppShell(
      child: SafeArea(
        child: Column(
          children: [
            const TopBar(title: 'Сообщество'),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Ошибка: $e')),
                data: (state) => RefreshIndicator(
                  onRefresh: () => ref
                      .read(communityDetailsControllerProvider(communityTitle).notifier)
                      .refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: 1 + state.posts.length, // 1 = хедер-карточка
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _CommunityHeaderCard(
                            title: state.community.title,
                            description: state.community.description,
                            members: state.community.membersCount,
                            isSubscribed: state.community.isSubscribed,
                            onToggleSubscribe: () => ref
                                .read(
                              communityDetailsControllerProvider(communityTitle).notifier,
                            )
                                .toggleSubscribe(),
                          ),
                        );
                      }

                      final post = state.posts[index - 1];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: CommunityPostCard(post: post),
                      );
                    },
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

class _CommunityHeaderCard extends StatelessWidget {
  static const _blue = Color(0xFF3F4F86);

  final String title;
  final String description;
  final int members;
  final bool isSubscribed;
  final VoidCallback onToggleSubscribe;

  const _CommunityHeaderCard({
    required this.title,
    required this.description,
    required this.members,
    required this.isSubscribed,
    required this.onToggleSubscribe,
  });

  @override
  Widget build(BuildContext context) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.person, size: 18, color: Colors.black38),
              const SizedBox(width: 6),
              Text('$members участников',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              const Spacer(),
              SizedBox(
                height: 34,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: isSubscribed ? Colors.grey : _blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: onToggleSubscribe,
                  child: Text(isSubscribed ? 'Отписаться' : 'Подписаться'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class CommunityPostCard extends StatelessWidget {
  final CommunityPost post;
  const CommunityPostCard({super.key, required this.post});

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
                  onSelected: (v) {
                    if (v == 1) {
                      Navigator.of(context).pushNamed(
                        PostDetailsScreen.routeName,
                        arguments: post.id, // ✅ только id
                      );
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 1, child: Text('Перейти')),
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
                Text('${post.likes}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(width: 16),
                const Icon(Icons.chat_bubble_outline, size: 18, color: Color(0xFF3F4F86)),
                const SizedBox(width: 6),
                Text('${post.comments}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(
                      Icons.share,
                      size: 18,
                    color: Color(0xFF3F4F86),
                  ),
                  label: const Text(
                      'Поделиться',
                    style: TextStyle(
                      color: Color(0xFF3F4F86)
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
