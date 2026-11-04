import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oman_agri/features/crops/data/knowledge_repository.dart';
import 'package:oman_agri/features/crops/data/models.dart';
import 'package:oman_agri/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

final _firstStrong = RegExp('[A-Za-z\u00C0-\u024F\u0590-\u08FF]');
final _rtlLetter = RegExp('[\u0590-\u08FF]');

/// Direction of [text] taken from its first strong (letter) character, so an
/// Arabic title renders RTL and a Latin one LTR whatever the app locale.
TextDirection textDirectionOf(String text) {
  final m = _firstStrong.firstMatch(text);
  return m != null && _rtlLetter.hasMatch(m[0]!)
      ? TextDirection.rtl
      : TextDirection.ltr;
}

/// The parsed [url] when it is an absolute http(s) link, else null. Anything
/// else (javascript:, file:, scheme-less text) is never offered as a link.
Uri? safeSourceUri(String? url) {
  if (url == null || url.isEmpty) return null;
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) return null;
  return uri.scheme == 'http' || uri.scheme == 'https' ? uri : null;
}

/// Icon button that opens a bottom sheet describing where a fact came from.
class SourceButton extends ConsumerWidget {
  const SourceButton({super.key, required this.sourceId, this.page, this.color});

  final String sourceId;
  final String? page;

  /// Icon colour; defaults to the theme's.
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      tooltip: l10n.source,
      // Quiet by default: present on every fact, so it must not shout.
      color: color ?? Theme.of(context).colorScheme.outline,
      iconSize: 20,
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.menu_book_outlined),
      onPressed: () {
        final source = ref.read(knowledgeProvider).asData?.value.sources[sourceId];
        showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          builder: (_) => _SourceSheet(source: source, sourceId: sourceId, page: page),
        );
      },
    );
  }
}

class _SourceSheet extends StatelessWidget {
  const _SourceSheet({required this.source, required this.sourceId, this.page});

  final Source? source;
  final String sourceId;
  final String? page;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = source;
    final uri = safeSourceUri(s?.url);
    final title = s?.title ?? sourceId;
    Widget line(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text.rich(TextSpan(children: [
            TextSpan(
                text: '$label: ',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ])),
        );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.source, style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(title,
                textDirection: textDirectionOf(title),
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (s != null && s.publisher.isNotEmpty)
              line(l10n.sourcePublisher, s.publisher),
            if (s?.year != null) line(l10n.sourceYear, '${s!.year}'),
            if (page != null && page!.isNotEmpty) line(l10n.sourcePage, page!),
            if (uri != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.open_in_new),
                title: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(s!.url!,
                      style: TextStyle(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline)),
                ),
                subtitle: Text(l10n.openLink),
                onTap: () => _open(context, uri),
              ),
          ],
        ),
      ),
    );
  }

  /// Opens [uri] externally. On failure the sheet closes (a snackbar would be
  /// hidden behind it) and a snackbar explains the problem.
  Future<void> _open(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final navigator = Navigator.of(context);
    final message = AppLocalizations.of(context).linkOpenFailed;
    bool ok;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (ok) return;
    if (navigator.mounted) navigator.maybePop();
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
