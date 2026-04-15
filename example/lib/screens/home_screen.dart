import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../example_log_controller.dart';
import '../test_config_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.config,
    required this.log,
    required this.initialUrl,
    required this.onRefreshInitial,
  });

  final DeeplinkTestConfig config;
  final ExampleLogController log;
  final String? initialUrl;
  final VoidCallback onRefreshInitial;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: log,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Deeplink SDK example',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(config.meta['description'] as String? ?? ''),
            const SizedBox(height: 16),
            Text('Sample short code: ${config.sampleShortCode}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: config.sampleShortCode));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied short code')),
                        );
                      }
                    },
                    child: const Text('Copy short code'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Initial URL (native)', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            SelectableText(initialUrl ?? '(none — open app via a link)'),
            TextButton.icon(
              onPressed: onRefreshInitial,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh initial URL'),
            ),
            const SizedBox(height: 16),
            Text('Smart status', style: Theme.of(context).textTheme.titleSmall),
            Text(log.smartStatus),
            const SizedBox(height: 16),
            Text('Adb (Android)', style: Theme.of(context).textTheme.titleSmall),
            ...config.adb.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                    SelectableText(e.value),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: e.value));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Copied adb command')),
                            );
                          }
                        },
                        child: const Text('Copy'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('Sample API envelope (from JSON)', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            SelectableText(
              JsonEncoder.withIndent('  ').convert(config.sampleApiResponseShape ?? {}),
            ),
          ],
        );
      },
    );
  }
}
