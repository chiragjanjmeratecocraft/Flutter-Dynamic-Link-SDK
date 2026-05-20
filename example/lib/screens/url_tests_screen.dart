import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../example_log_controller.dart';
import '../test_config_model.dart';

class UrlTestsScreen extends StatelessWidget {
  const UrlTestsScreen({
    super.key,
    required this.config,
    required this.log,
  });

  final DeeplinkTestConfig config;
  final ExampleLogController log;

  Future<void> _open(BuildContext context, TestUrlItem item) async {
    log.log('Open externally: ${item.url}');
    final uri = Uri.parse(item.url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch URL')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Open test URLs', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text(
          '“Open” uses the system browser / handler. For in-app deep links, prefer adb (Home tab) or kill the app and open the link so the OS routes to this app.',
        ),
        const SizedBox(height: 16),
        ...config.testUrls.map((item) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  SelectableText(item.url),
                  if (item.notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(item.notes, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton(
                        onPressed: () => _open(context, item),
                        child: const Text('Open'),
                      ),
                      OutlinedButton(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: item.url));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Copied URL')),
                            );
                          }
                        },
                        child: const Text('Copy URL'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
