import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'deeplink_example_app.dart';
import 'test_config_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final raw = await rootBundle.loadString('assets/deeplink_test_config.json');
  final config = DeeplinkTestConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  runApp(DeeplinkExampleApp(config: config));
}
