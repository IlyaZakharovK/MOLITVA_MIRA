import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/communities/community_item.dart';
import '../community_details/community_details_screen.dart';
import '../shell/app_shell.dart';
import '../widgets/top_bar.dart';
import 'communities_controller.dart';

class CommunitiesScreen extends ConsumerStatefulWidget {
  final bool my;
  const CommunitiesScreen({super.key, required this.my});

  @override
  ConsumerState<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends ConsumerState<CommunitiesScreen> {
  late final ScrollController _scroll;
  bool get _my => widget.my;

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
    if (p.pixels >= p.maxScrollExtent - 280) {
      ref.read(communitiesControllerProvider(_my).notifier).loadMore();
    }
  }

  Future<void> _openCreateGroupSheet(BuildContext context) async {
    final res = await showModalBottomSheet<_CreateGroupResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateGroupSheet(),
    );

    if (res == null) return;

    final ok = await ref.read(communitiesControllerProvider(_my).notifier).createGroup(
      type: res.type,
      name: res.name,
      description: res.description,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Сообщество создано' : 'Не удалось создать')),
    );
  }

  Future<void> _openSearchSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<CommunityItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommunitiesSearchSheet(
        onSearch: (q) => ref
            .read(communitiesControllerProvider(_my).notifier)
            .searchCommunities(q),
      ),
    );

    if (selected == null) return;
    if (!mounted) return;

    // Пока заглушка — ты просил оставить так.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Открыть сообщество: ${selected.name}')),
    );

    // Если хочешь включить реальную навигацию прямо сейчас — раскомментируй:
    // Navigator.of(context).pushNamed(
    //   CommunityDetailsScreen.routeName,
    //   arguments: selected.name,
    // );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(communitiesControllerProvider(_my));

    return AppShell(
      child: SafeArea(
        child: Column(
          children: [
            const TopBar(title: 'Сообщества'),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _openCreateGroupSheet(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF3F4F86),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Создать сообщество'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (!_my) ... [SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () => _openSearchSheet(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0x22000000)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        textStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      icon: const Icon(Icons.search),
                      label: const Text('Поиск'),
                    ),
                  ),]
                ],
              ),
            ),
            Expanded(
              child: async.when(
                loading: () =>
                const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Ошибка: $e')),
                data: (st) => RefreshIndicator(
                  onRefresh: () =>
                      ref.read(communitiesControllerProvider(_my).notifier).refresh(),
                  child: Stack(
                    children: [
                      ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                        itemCount: st.items.length,
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CommunityCard(
                            item: st.items[i],
                            isBusy: st.pendingSubActions.contains(st.items[i].id),
                            onToggleSub: (action) async {
                              final ok = await ref
                                  .read(communitiesControllerProvider(_my).notifier)
                                  .subUnSub(
                                action: action,
                                groupId: st.items[i].id,
                              );

                              if (!context.mounted) return;
                              if (!ok) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Не удалось выполнить действие')),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                      if (st.isLoadingMore)
                        const Positioned(
                          left: 0,
                          right: 0,
                          bottom: 10,
                          child:
                          Center(child: CircularProgressIndicator()),
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

class _CommunityCard extends StatelessWidget {
  final CommunityItem item;
  final bool isBusy;
  final Future<void> Function(int action) onToggleSub;

  const _CommunityCard({
    required this.item,
    required this.isBusy,
    required this.onToggleSub,
  });

  @override
  Widget build(BuildContext context) {
    final title = item.name;
    final subtitle = item.description;
    final members = item.subscribers;

    final btnText = item.subed ? 'Вы подписаны' : 'Подписаться';

    final btnEnabled = !isBusy;

    void openDetails() {
      Navigator.of(context).pushNamed(
        CommunityDetailsScreen.routeName,
        arguments: {"communityID":item.id},
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: openDetails,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                blurRadius: 18,
                color: Color(0x14000000),
                offset: Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CommunityAvatar(url: item.image),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 34,
                      child: FilledButton(
                        onPressed: btnEnabled
                            ? () => onToggleSub(item.subed ? 2 : 1)
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: item.subed
                              ? const Color.fromARGB(255, 10, 179, 156)
                              : const Color(0xFF2F80ED),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        child: Text(
                          isBusy ? '...' : btnText,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const SizedBox(height: 48),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 18, color: Colors.black38),
                      const SizedBox(width: 4),
                      Text(
                        members.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommunityAvatar extends StatelessWidget {
  final String url;

  const _CommunityAvatar({required this.url});

  @override
  Widget build(BuildContext context) {
    final hasUrl = url.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 64,
        height: 64,
        color: const Color(0xFFF0F0F0),
        alignment: Alignment.center,
        child: hasUrl
            ? Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
          const Icon(Icons.group_outlined, size: 30),
        )
            : const Icon(Icons.group_outlined, size: 30),
      ),
    );
  }
}

/* ===========================
   CREATE GROUP SHEET
   =========================== */

class _CreateGroupResult {
  final int type; // 1 open, 2 closed
  final String name;
  final String description;

  const _CreateGroupResult({
    required this.type,
    required this.name,
    required this.description,
  });
}

class _CreateGroupSheet extends StatefulWidget {
  const _CreateGroupSheet();

  @override
  State<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<_CreateGroupSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  int _type = 1;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _descCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    if (name.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните название и описание')),
      );
      return;
    }

    Navigator.of(context).pop(
      _CreateGroupResult(type: _type, name: name, description: desc),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                    'Создать сообщество',
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 10,
                children: [
                  ChoiceChip(
                    label: const Text('Открытое'),
                    selected: _type == 1,
                    onSelected: (_) => setState(() => _type = 1),
                  ),
                  ChoiceChip(
                    label: const Text('Закрытое'),
                    selected: _type == 2,
                    onSelected: (_) => setState(() => _type = 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Название',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Описание',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                onPressed: _submit,
                child: const Text('Создать'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunitiesSearchSheet extends StatefulWidget {
  final Future<List<CommunityItem>> Function(String query) onSearch;

  const _CommunitiesSearchSheet({required this.onSearch});

  @override
  State<_CommunitiesSearchSheet> createState() =>
      _CommunitiesSearchSheetState();
}

class _CommunitiesSearchSheetState extends State<_CommunitiesSearchSheet> {
  late final TextEditingController _ctrl;

  bool _loading = false;
  String? _error;
  List<CommunityItem> _items = const [];

  String _lastRequested = '';
  int _token = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleChanged(String raw) async {
    final q = raw.trim();

    if (q.isEmpty) {
      setState(() {
        _items = const [];
        _loading = false;
        _error = null;
        _lastRequested = '';
      });
      return;
    }

    if (q.length < 3) {
      setState(() {
        _items = const [];
        _loading = false;
        _error = null;
        _lastRequested = '';
      });
      return;
    }

    // ✅ Триггер строго на 3/6/9/...
    if (q.length % 3 != 0) return;

    if (_lastRequested == q) return;
    _lastRequested = q;

    final myToken = ++_token;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final found = await widget.onSearch(q);
      if (!mounted || myToken != _token) return;

      setState(() {
        _items = found;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted || myToken != _token) return;

      setState(() {
        _items = const [];
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
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
                    const Expanded(
                      child: Text(
                        'Поиск сообщества',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF3F4F86),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _ctrl,
                  autofocus: true,
                  onChanged: _handleChanged,
                  decoration: InputDecoration(
                    hintText: 'Введите название…',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF6F7F9),
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                child: Stack(
                  children: [
                    if (_error != null)
                      ListView(
                        controller: scrollCtrl,
                        children: [
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Ошибка поиска:\n$_error',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.redAccent,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      )
                    else if (_ctrl.text.trim().length < 3)
                      ListView(
                        controller: scrollCtrl,
                        children: const [
                          SizedBox(height: 24),
                          Center(
                            child: Text(
                              'Введите минимум 3 символа',
                              style:
                              TextStyle(fontSize: 13, color: Colors.black54),
                            ),
                          ),
                        ],
                      )
                    else if (_items.isEmpty && !_loading)
                        ListView(
                          controller: scrollCtrl,
                          children: const [
                            SizedBox(height: 24),
                            Center(
                              child: Text(
                                'Ничего не найдено',
                                style:
                                TextStyle(fontSize: 13, color: Colors.black54),
                              ),
                            ),
                          ],
                        )
                      else
                        ListView.separated(
                          controller: scrollCtrl,
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final it = _items[i];
                            return ListTile(
                              title: Text(
                                it.name,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                              subtitle: it.description.isEmpty
                                  ? null
                                  : Text(
                                it.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black54),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.person_outline,
                                      size: 16, color: Colors.black38),
                                  const SizedBox(width: 4),
                                  Text(
                                    it.subscribers.toString(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.of(ctx).pop();
                                Navigator.of(context).pushNamed(
                                  CommunityDetailsScreen.routeName,
                                  arguments: it.id,
                                );
                              },
                            );
                          },
                        ),
                    if (_loading)
                      const Positioned(
                        left: 0,
                        right: 0,
                        top: 10,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}