import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../community_details/community_details_screen.dart';
import '../shell/app_shell.dart';
import '../widgets/top_bar.dart';
import '../../domain/news/news_item.dart';
import 'news_controller.dart';

class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key});

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen> {
  late final ScrollController _scroll;

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
      ref.read(newsControllerProvider.notifier).loadMore().catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(newsControllerProvider);

    return AppShell(
      child: SafeArea(
        child: Column(
          children: [
            const TopBar(title: 'Новости сообществ'),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Ошибка: $e')),
                data: (st) => RefreshIndicator(
                  onRefresh: () => ref.read(newsControllerProvider.notifier).refresh(),
                  child: Stack(
                    children: [
                      ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                        itemCount: 1 + st.items.length,
                        itemBuilder: (context, i) {
                          if (i == 0) {
                            return const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: _PageHeaderRow(),
                            );
                          }

                          final post = st.items[i - 1];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _NewsPostCard(post: post),
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

class _PageHeaderRow extends StatelessWidget {
  const _PageHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: Text(
            'НОВОСТИ СООБЩЕСТВ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
              color: Colors.black87,
            ),
          ),
        ),
        Text(
          'Последние новости',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black45,
          ),
        ),
      ],
    );
  }
}

class _NewsPostCard extends StatelessWidget {
  static const _blue = Color(0xFF3F4F86);

  final NewsPost post;
  const _NewsPostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final dt = _ruDateTime(post.dateAdd);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            blurRadius: 16,
            color: Color(0x14000000),
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                _GroupLogo(url: post.groupLogoUrl),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    post.groupName,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 30,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _blue,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        CommunityDetailsScreen.routeName,
                        arguments: {
                          'communityID': post.groupId,
                          'invited': false,
                          'invite': '',
                        },
                      );
                    },
                    child: const Text('Перейти в сообщество'),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // body
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  maxLines: 3,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.calendar_month, size: 16, color: Colors.black38),
                    const SizedBox(width: 6),
                    Text(
                      dt,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.person_outline, size: 16, color: Colors.black38),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        post.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
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
                    color: Colors.black87,
                    height: 1.35,
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
      ),
    );
  }
}

class _GroupLogo extends StatelessWidget {
  final String url;
  const _GroupLogo({required this.url});

  @override
  Widget build(BuildContext context) {
    final has = url.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        color: const Color(0xFFF0F2F4),
        alignment: Alignment.center,
        child: has
            ? Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
          const Icon(Icons.group_outlined, color: Colors.black38),
        )
            : const Icon(Icons.group_outlined, color: Colors.black38),
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