import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/prays/pray_category_item.dart';
import '../../domain/prays/pray_list_item.dart';
import '../shell/app_shell.dart';
import '../widgets/app_message_bar.dart';
import '../widgets/top_bar.dart';
import 'prays_controller.dart';

class PraysScreen extends ConsumerStatefulWidget {
  static const routeName = '/prays';

  const PraysScreen({super.key});

  @override
  ConsumerState<PraysScreen> createState() => _PraysScreenState();
}

class _PraysScreenState extends ConsumerState<PraysScreen> {
  final Set<int> _expandedCategories = <int>{};
  final Set<int> _expandedPrays = <int>{};

  static const String _prayRequestRouteName = '/pray';

  Future<void> _onRefresh() async {
    await ref.read(praysControllerProvider.notifier).reload();
  }

  void _onOpenPrayRequest({
    required PrayCategoryItem category,
    required PrayItem pray,
  }) {
    try {
      Navigator.of(context).pushNamed(
        _prayRequestRouteName,
        arguments: {
          'categoryId': category.id,
          'categoryName': category.name,
          'prayId': pray.id,
          'prayName': pray.name,
          'prayText': pray.text
        },
      );
    } catch (e) {
      showAppMessageBar(
        context,
        'Страница запроса молитвы ещё не подключена (route: $_prayRequestRouteName)',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(praysControllerProvider);

    return AppShell(
      child: SafeArea(
        child: Column(
          children: [
            const TopBar(title: "Молитвы",),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _ErrorState(
                  message: e.toString(),
                  onRetry: () => ref.read(praysControllerProvider.notifier).reload(),
                ),
                data: (st) {
                  if (st.error != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      showAppMessageBar(context, st.error!);
                    });
                  }

                  return RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: st.categories.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final cat = st.categories[i];
                        final isExpanded = _expandedCategories.contains(cat.id);
                        final isLoading = st.loadingCategoryIds.contains(cat.id);
                        final prays = st.praysByCategory[cat.id] ?? const <PrayItem>[];

                        return _CategoryCard(
                          title: cat.name,
                          expanded: isExpanded,
                          loading: isLoading,
                          children: prays,
                          onExpansionChanged: (v) {
                            setState(() {
                              if (v) {
                                _expandedCategories.add(cat.id);
                              } else {
                                _expandedCategories.remove(cat.id);
                              }
                            });
                            if (v) {
                              ref.read(praysControllerProvider.notifier).loadCategory(cat.id);
                            }
                          },
                          isPrayExpanded: (prayId) => _expandedPrays.contains(prayId),
                          onPrayExpansionChanged: (prayId, v) {
                            setState(() {
                              if (v) {
                                _expandedPrays.add(prayId);
                              } else {
                                _expandedPrays.remove(prayId);
                              }
                            });
                          },
                          onRequest: (pray) => _onOpenPrayRequest(category: cat, pray: pray),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.expanded,
    required this.loading,
    required this.children,
    required this.onExpansionChanged,
    required this.isPrayExpanded,
    required this.onPrayExpansionChanged,
    required this.onRequest,
  });

  final String title;
  final bool expanded;
  final bool loading;
  final List<PrayItem> children;
  final ValueChanged<bool> onExpansionChanged;

  final bool Function(int prayId) isPrayExpanded;
  final void Function(int prayId, bool expanded) onPrayExpansionChanged;
  final void Function(PrayItem pray) onRequest;

  @override
  Widget build(BuildContext context) {
    final border = BorderRadius.circular(8);

    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: border,
        side: const BorderSide(color: Color(0xFFE6E8EF)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey('cat_$title'),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          trailing: Icon(
            expanded ? Icons.keyboard_arrow_up : Icons.chevron_right,
            color: const Color(0xFF3F4F86),
          ),
          onExpansionChanged: onExpansionChanged,
          initiallyExpanded: expanded,
          children: [
            if (loading)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: LinearProgressIndicator(minHeight: 2),
              ),

            if (!loading && children.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('В этой категории пока нет молитв.'),
              ),

            for (final pray in children)
              _PrayTile(
                pray: pray,
                expanded: isPrayExpanded(pray.id),
                onExpansionChanged: (v) => onPrayExpansionChanged(pray.id, v),
                onRequest: () => onRequest(pray),
              ),
          ],
        ),
      ),
    );
  }
}

class _PrayTile extends StatelessWidget {
  const _PrayTile({
    required this.pray,
    required this.expanded,
    required this.onExpansionChanged,
    required this.onRequest,
  });

  final PrayItem pray;
  final bool expanded;
  final ValueChanged<bool> onExpansionChanged;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final border = BorderRadius.circular(8);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: const Color(0xFFF6F7F9),
        shape: RoundedRectangleBorder(
          borderRadius: border,
          side: const BorderSide(color: Color(0xFFE6E8EF)),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: PageStorageKey('pray_${pray.id}'),
            tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            title: Text(
              pray.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            trailing: Icon(
              expanded ? Icons.keyboard_arrow_up : Icons.chevron_right,
              color: const Color(0xFF3F4F86),
            ),
            onExpansionChanged: onExpansionChanged,
            initiallyExpanded: expanded,
            children: [
              Text(
                pray.text,
                style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton(
                  onPressed: onRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3F4F86),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('Запрос на молитву'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}
