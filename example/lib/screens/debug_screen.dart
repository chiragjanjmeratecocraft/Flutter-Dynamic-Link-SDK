import 'package:flutter/material.dart';
import 'package:my_deeplink_sdk/my_deeplink_sdk.dart';

import '../example_log_controller.dart';
import '../test_config_model.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({
    super.key,
    required this.config,
    required this.log,
    required this.onRestartSmartLinking,
  });

  final DeeplinkTestConfig config;
  final ExampleLogController log;
  final Future<void> Function() onRestartSmartLinking;

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  bool? _handledFirstInstall;
  String? _parseDemo;

  @override
  void initState() {
    super.initState();
    _refreshFlags();
  }

  Future<void> _refreshFlags() async {
    final h = await MyDeeplinkSdk.hasHandledFirstInstall();
    if (mounted) setState(() => _handledFirstInstall = h);
  }

  void _runParseDemo() {
    const pathUrl = 'https://backend-dynamiclink.tecocraft.us/3SxE2G';
    const queryUrl = 'mydeeplinksdk://open?short_code=3SxE2G';
    final q = MyDeeplinkSdk.extractShortCode(queryUrl);
    final p = MyDeeplinkSdk.extractShortCodeWithPathFallback(
      pathUrl,
      allowedHosts: {'backend-dynamiclink.tecocraft.us'},
    );
    setState(() {
      _parseDemo = 'Path URL: $pathUrl\npath extract: $p\n\nQuery URL: $queryUrl\nquery extract: $q';
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Debug', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ListTile(
          title: const Text('First-install flag handled'),
          subtitle: Text(_handledFirstInstall?.toString() ?? '…'),
          trailing: IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshFlags,
          ),
        ),
        FilledButton.tonal(
          onPressed: () async {
            await MyDeeplinkSdk.resetFirstInstallFlag();
            widget.log.log('Debug: resetFirstInstallFlag');
            await _refreshFlags();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('First-install flag cleared')),
              );
            }
          },
          child: const Text('Reset first-install flag'),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () async {
            widget.log.log('Debug: restart smart linking');
            await widget.onRestartSmartLinking();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Smart linking restarted')),
              );
            }
          },
          child: const Text('Restart smart linking'),
        ),
        const Divider(height: 32),
        Text('Parse demo', style: Theme.of(context).textTheme.titleSmall),
        TextButton(onPressed: _runParseDemo, child: const Text('Run extractShortCode demo')),
        SelectableText(_parseDemo ?? 'Tap “Run” to see query vs path extraction.'),
        const Divider(height: 32),
        Text('sdk_init from JSON', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SelectableText(widget.config.sdkInit.toString()),
      ],
    );
  }
}
