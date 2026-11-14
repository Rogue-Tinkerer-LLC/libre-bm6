import 'package:flutter/material.dart';

import 'about_page.dart';
import 'app_env.dart';
import 'ble.dart';
import 'help_page.dart';
import 'l10n/app_localizations.dart';
import 'legal_page.dart';
import 'monitor_page.dart';
import 'scanner_page.dart';
import 'store.dart';

enum _DeviceAction { rename, delete }

/// Home: the saved monitors.
class DevicesPage extends StatelessWidget {
  const DevicesPage({
    super.key,
    required this.store,
    required this.ble,
    required this.env,
  });

  final Store store;
  final Ble ble;
  final AppEnv env;

  void _push(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  Future<void> _onAction(
    BuildContext context,
    SavedDevice device,
    _DeviceAction action,
  ) async {
    final l = AppLocalizations.of(context);
    switch (action) {
      case _DeviceAction.rename:
        final alias = await showAliasDialog(
          context,
          title: l.renameTitle,
          initial: device.alias,
        );
        if (alias != null) await store.save(device.id, alias);
      case _DeviceAction.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l.deleteTitle),
            content: Text(l.deleteMessage(device.alias)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l.delete),
              ),
            ],
          ),
        );
        if (confirmed ?? false) await store.remove(device.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.devicesTitle)),
      drawer: _HomeDrawer(env: env),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final devices = store.devices;
          if (devices.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l.devicesEmpty, textAlign: TextAlign.center),
              ),
            );
          }
          return ListView(
            children: [
              for (final device in devices)
                ListTile(
                  title: Text(device.alias),
                  subtitle: Text(device.id),
                  onTap: () =>
                      _push(context, MonitorPage(ble: ble, device: device)),
                  trailing: PopupMenuButton<_DeviceAction>(
                    tooltip: l.deviceActionsTooltip(device.alias),
                    onSelected: (action) => _onAction(context, device, action),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: _DeviceAction.rename,
                        child: Text(l.rename),
                      ),
                      PopupMenuItem(
                        value: _DeviceAction.delete,
                        child: Text(l.delete),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: l.addDeviceTooltip,
        onPressed: () => _push(context, ScannerPage(ble: ble, store: store)),
        icon: const Icon(Icons.add),
        label: Text(l.addDevice),
      ),
    );
  }
}

class _HomeDrawer extends StatelessWidget {
  const _HomeDrawer({required this.env});

  final AppEnv env;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    void open(Widget page) {
      final navigator = Navigator.of(context)..pop();
      navigator.push(MaterialPageRoute<void>(builder: (_) => page));
    }

    return Drawer(
      child: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l.drawerAbout),
            onTap: () => open(AboutPage(env: env)),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text(l.helpTitle),
            onTap: () => open(HelpPage(env: env)),
          ),
          ListTile(
            leading: const Icon(Icons.gavel),
            title: Text(l.termsTitle),
            onTap: () => open(const TermsPage()),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l.privacyTitle),
            onTap: () => open(const PrivacyPage()),
          ),
        ],
      ),
    );
  }
}

/// Asks for a device name. Returns null if cancelled or left blank.
Future<String?> showAliasDialog(
  BuildContext context, {
  required String title,
  required String initial,
}) => showDialog<String>(
  context: context,
  builder: (context) => _AliasDialog(title: title, initial: initial),
);

class _AliasDialog extends StatefulWidget {
  const _AliasDialog({required this.title, required this.initial});

  final String title;
  final String initial;

  @override
  State<_AliasDialog> createState() => _AliasDialogState();
}

class _AliasDialogState extends State<_AliasDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final alias = _controller.text.trim();
    Navigator.of(context).pop(alias.isEmpty ? null : alias);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: l.aliasLabel),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        TextButton(onPressed: _submit, child: Text(l.save)),
      ],
    );
  }
}
