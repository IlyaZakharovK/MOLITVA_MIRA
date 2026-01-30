import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

/// NOTE:
/// Для рендера HTML используется пакет `flutter_widget_from_html`.
/// Добавь в pubspec.yaml:
/// flutter_widget_from_html: ^0.16.0

enum AgreeDocType {
  privacy(1, 'Политика конфиденциальности'),
  terms(2, 'Пользовательское соглашение');

  const AgreeDocType(this.apiType, this.title);
  final int apiType;
  final String title;
}

/// Мини-API клиент под метод getAgree.
class AgreeApi {
  AgreeApi(this._dio);

  final Dio _dio;

  static const _type = 'application';
  static const _pass = 'f92R*#eiDF82W@#k2WO';

  static final Map<int, String> _cache = {};

  Future<String> getAgreeHtml(AgreeDocType docType) async {
    final cached = _cache[docType.apiType];
    if (cached != null && cached.isNotEmpty) return cached;

    final resp = await _dio.post(
      '',
      data: <String, dynamic>{
        'type': _type,
        'pass': _pass,
        'method': 'getAgree',
        'data': <String, dynamic>{'type': docType.apiType},
      },
    );

    final body = resp.data;
    if (body is! Map) throw Exception('Некорректный ответ сервера');

    final status = (body['status'] ?? '').toString();
    if (status != 'success') {
      throw Exception((body['description'] ?? 'Ошибка').toString());
    }

    final data = body['data'];
    if (data is! Map) throw Exception('В ответе нет data');

    final raw = (data['text'] ?? '').toString();
    final decoded = _htmlEntityDecode(raw);
    _cache[docType.apiType] = decoded;
    return decoded;
  }

  /// Сервер отдаёт HTML как строку, где теги экранированы (&lt;...&gt;).
  /// Декодируем самые частые энтити.
  static String _htmlEntityDecode(String s) {
    return s
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#34;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&');
  }
}

/// Показывает модалку с HTML-текстом документа.
///
/// Использование (из ConsumerWidget/ConsumerState):
///   final dio = ref.read(dioProvider);
///   showAgreeDialog(context, dio: dio, docType: AgreeDocType.privacy);
Future<void> showAgreeDialog(
    BuildContext context, {
      required Dio dio,
      required AgreeDocType docType,
    }) {
  return showDialog<void>(
    context: context,
    builder: (_) => AgreeDialog(dio: dio, docType: docType),
  );
}

class AgreeDialog extends StatefulWidget {
  final Dio dio;
  final AgreeDocType docType;

  const AgreeDialog({
    super.key,
    required this.dio,
    required this.docType,
  });

  @override
  State<AgreeDialog> createState() => _AgreeDialogState();
}

class _AgreeDialogState extends State<AgreeDialog> {
  late final AgreeApi _api;
  late Future<String> _future;

  @override
  void initState() {
    super.initState();
    _api = AgreeApi(widget.dio);
    _future = _api.getAgreeHtml(widget.docType);
  }

  void _reload() {
    setState(() {
      _future = _api.getAgreeHtml(widget.docType);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 680),
        child: Column(
          children: [
            _Header(
              title: widget.docType.title,
              onClose: () => Navigator.of(context).pop(),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<String>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return _ErrorState(
                      error: snap.error.toString(),
                      onRetry: _reload,
                    );
                  }

                  final html = (snap.data ?? '').trim();
                  if (html.isEmpty) {
                    return _ErrorState(
                      error: 'Пустой текст документа',
                      onRetry: _reload,
                    );
                  }

                  // Вставим лёгкую обёртку, чтобы заголовки/абзацы выглядели аккуратнее.
                  final wrapped = _wrapHtml(html);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                    child: HtmlWidget(
                      wrapped,
                      textStyle: const TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: Colors.black87,
                      ),
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

  static String _wrapHtml(String html) {
    // Сервер иногда присылает много пробелов/переносов в начале.
    final clean = html.replaceFirst(RegExp(r'^\s+'), '');
    return '''
<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, sans-serif; }
    h1,h2,h3 { margin: 16px 0 8px; }
    p { margin: 10px 0; }
    ul { padding-left: 18px; }
    li { margin: 6px 0; }
    a { color: #3F4F86; }
  </style>
</head>
<body>
$clean
</body>
</html>
''';
  }
}

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const _Header({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 36, color: Colors.red),
          const SizedBox(height: 10),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}

/// Твой старый виджет — оставил как был, чтобы ничего не ломать.
class AgreementRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onOpenPrivacy;
  final VoidCallback onOpenTerms;
  final bool showError;

  const AgreementRow({
    required this.value,
    required this.onChanged,
    required this.onOpenPrivacy,
    required this.onOpenTerms,
    required this.showError,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = showError ? Colors.red : Colors.transparent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 18,
            width: 18,
            child: Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              side: const BorderSide(color: Colors.black26),
              activeColor: const Color(0xFF0A2A52),
              checkColor: Colors.white,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'принимаю условия ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),
                InkWell(
                  onTap: onOpenPrivacy,
                  child: const Text(
                    'политики конфиденциальности',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF3F4F86),
                      decoration: TextDecoration.underline,
                      height: 1.2,
                    ),
                  ),
                ),
                const Text(
                  ' и ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),
                InkWell(
                  onTap: onOpenTerms,
                  child: const Text(
                    'пользовательского соглашения',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF3F4F86),
                      decoration: TextDecoration.underline,
                      height: 1.2,
                    ),
                  ),
                ),
                const Text(
                  ' *',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.red,
                    height: 1.2,
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
