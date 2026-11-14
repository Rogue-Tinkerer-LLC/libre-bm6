import 'package:flutter/material.dart';

import 'app_env.dart';
import 'l10n/app_localizations.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key, required this.env});

  final AppEnv env;

  Future<void> _openIssue(
    BuildContext context,
    String Function(String details) body,
  ) async {
    final l = AppLocalizations.of(context);
    final info = await env.info();
    final details = l.bugDetails(
      info.version,
      info.build,
      info.androidRelease,
      info.sdkLevel,
    );
    final opened = await env.openUri(newIssueUri(body(details)));
    if (opened || !context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: SelectableText(l.noBrowser('$issuesUrl/new')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.helpTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.helpIntro, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.support_outlined),
            label: Text(l.contactSupport),
            onPressed: () => _openIssue(context, l.supportBody),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.bug_report_outlined),
            label: Text(l.reportBug),
            onPressed: () => _openIssue(context, l.bugBody),
          ),
        ],
      ),
    );
  }
}
