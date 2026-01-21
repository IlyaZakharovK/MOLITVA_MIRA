import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../community_details/community_details_screen.dart';
import '../shell/app_shell.dart';

import '../../domain/my_communities/my_community_item.dart';
import '../../domain/my_communities/my_community_tab.dart';
import '../widgets/top_bar.dart';
import 'my_communities_controller.dart';

class MyCommunitiesScreen extends ConsumerWidget {
  const MyCommunitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(myCommunitiesTabProvider);
    final async = ref.watch(filteredMyCommunitiesProvider);

    return AppShell(
      child: SafeArea(
        child: Column(
          children: [
            const TopBar(title: 'Мои сообщества'),
            _TabsRow(
              value: tab,
              onChanged: (v) =>
                  ref.read(myCommunitiesTabProvider.notifier).state = v,
            ),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Ошибка: $e')),
                data: (items) => RefreshIndicator(
                  onRefresh: () => ref
                      .read(myCommunitiesControllerProvider.notifier)
                      .refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: items.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _MyCommunityCard(item: items[i]),
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

class _TabsRow extends StatelessWidget {
  final MyCommunityTab value;
  final ValueChanged<MyCommunityTab> onChanged;

  const _TabsRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // ✅ центрируем блок кнопок
        children: [
          _TabChip(
            text: MyCommunityTab.subscribed.label,
            active: value == MyCommunityTab.subscribed,
            onTap: () => onChanged(MyCommunityTab.subscribed),
          ),
          const SizedBox(width: 10),
          _TabChip(
            text: MyCommunityTab.mine.label,
            active: value == MyCommunityTab.mine,
            onTap: () => onChanged(MyCommunityTab.mine),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String text;
  final bool active;
  final VoidCallback onTap;

  const _TabChip({
    required this.text,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = active ? const Color(0xFF3F4F86) : Colors.white;
    final fg = active ? Colors.white : Colors.black54;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.black12),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ),
    );
  }
}

class _MyCommunityCard extends StatelessWidget {
  static const _blue = Color(0xFF3F4F86);

  final MyCommunityItem item;

  const _MyCommunityCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).pushNamed(
            CommunityDetailsScreen.routeName,
            arguments: item.title, // пока по названию
          );
        },
        child: Container(
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    item.imageAsset,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(height: 180, color: _blue),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Column(
                  children: [
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.black45,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.black38),
                    const SizedBox(width: 4),
                    Text(
                      item.membersCount.toString(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.black45,
                      ),
                    ),
                    const Spacer(),
                    if (item.isMine)
                      const Text(
                        'Вы создатель',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _blue,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
