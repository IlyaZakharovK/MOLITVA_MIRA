import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../community_details/community_details_screen.dart';
import '../shell/app_shell.dart';
import '../widgets/top_bar.dart';
import 'communities_controller.dart';

class CommunitiesScreen extends ConsumerWidget {
  const CommunitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(communitiesControllerProvider);

    return AppShell(
      child: SafeArea(
        child: Column(
          children: [
            const TopBar(title: 'Сообщества'),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Ошибка: $e')),
                data: (items) => RefreshIndicator(
                  onRefresh: () => ref.read(communitiesControllerProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                    itemCount: items.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CommunityCard(
                        title: items[i].title,
                        subtitle: items[i].subtitle,
                        members: items[i].members,
                        imageAsset: items[i].imageAsset,
                        onJoin: () => ref.read(communitiesControllerProvider.notifier).join(items[i].id),
                      ),
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

class _CommunityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int members;
  final String? imageAsset;
  final VoidCallback onJoin;

  const _CommunityCard({
    required this.title,
    required this.subtitle,
    required this.members,
    required this.onJoin,
    this.imageAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            blurRadius: 20,
            color: Color(0x14000000),
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF3F4F86), width: 2),
            ),
            child: ClipOval(
              child: imageAsset == null
                  ? const Center(child: Icon(Icons.menu_book, color: Color(0xFF3F4F86)))
                  : Image.asset(
                imageAsset!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                const Center(child: Icon(Icons.menu_book, color: Color(0xFF3F4F86))),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, height: 1.15),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.black38),
                        const SizedBox(width: 4),
                        Text(
                          members.toString(),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black45),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.black54, height: 1.2),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    height: 28,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                    children: [
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF3F4F86),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        onPressed: onJoin,
                        child: const Text('Вступить'),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF3F4F86),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            CommunityDetailsScreen.routeName,
                            arguments: title, // или item.title
                          );
                        },
                        child: const Text('Перейти'),
                      ),
                    ],
                                        )
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
