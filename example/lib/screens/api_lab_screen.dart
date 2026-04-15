import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:my_deeplink_sdk/my_deeplink_sdk.dart';

import '../deeplink_router.dart';
import '../example_log_controller.dart';
import '../test_config_model.dart';

class ApiLabScreen extends StatefulWidget {
  const ApiLabScreen({
    super.key,
    required this.config,
    required this.log,
    this.linkNavigatorKey,
  });

  final DeeplinkTestConfig config;
  final ExampleLogController log;
  /// When set, a successful code lookup runs the same navigation as smart linking.
  final GlobalKey<NavigatorState>? linkNavigatorKey;

  @override
  State<ApiLabScreen> createState() => _ApiLabScreenState();
}

class _ApiLabScreenState extends State<ApiLabScreen> {
  late final TextEditingController _codeController;
  String _output = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.config.sampleShortCode);
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _fetchByCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _busy = true;
      _output = '';
    });
    widget.log.log('API: getLinkByCodeTyped($code)');
    try {
      final data = await MyDeeplinkSdk.getLinkByCodeTyped(code);
      final json = <String, dynamic>{
        'short_code': data.shortCode,
        'link_id': data.linkId,
        'customData': data.customData,
        'project': {
          'id': data.project.id,
          'name': data.project.name,
        },
      };
      setState(() {
        _output = const JsonEncoder.withIndent('  ').convert(json);
      });
      widget.log.log('API: success ${data.shortCode}');
      final navKey = widget.linkNavigatorKey;
      if (navKey != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigateForLinkData(navKey, data);
        });
      }
    } catch (e, st) {
      setState(() {
        _output = '$e\n$st';
      });
      widget.log.log('API: error $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pending() async {
    setState(() {
      _busy = true;
      _output = '';
    });
    widget.log.log('API: postPendingRedirectTyped()');
    try {
      final data = await MyDeeplinkSdk.postPendingRedirectTyped();
      setState(() {
        _output = const JsonEncoder.withIndent('  ').convert({
          'short_code': data.shortCode,
          'link_id': data.linkId,
          'customData': data.customData,
          'project': {
            'id': data.project.id,
            'name': data.project.name,
          },
        });
      });
      widget.log.log('API: pending shortCode=${data.shortCode}');
    } catch (e, st) {
      setState(() {
        _output = '$e\n$st';
      });
      widget.log.log('API: pending error $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('API lab', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        TextField(
          controller: _codeController,
          decoration: const InputDecoration(
            labelText: 'Short code',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            FilledButton(
              onPressed: _busy ? null : _fetchByCode,
              child: const Text('GET /code/{code} (typed)'),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: _busy ? null : _pending,
              child: const Text('POST pending-redirect'),
            ),
          ],
        ),
        if (_busy) const LinearProgressIndicator(),
        const SizedBox(height: 16),
        Text('Result', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SelectableText(_output.isEmpty ? '(empty)' : _output),
      ],
    );
  }
}
