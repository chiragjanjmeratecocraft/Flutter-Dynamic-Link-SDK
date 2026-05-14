// import 'package:flutter/foundation.dart';
//
// class ExampleLogController extends ChangeNotifier {
//   ExampleLogController();
//
//   final List<String> _lines = <String>[];
//   String smartStatus = 'Idle';
//
//   List<String> get lines => List<String>.unmodifiable(_lines);
//
//   void log(String line) {
//     final ts = DateTime.now().toIso8601String();
//     _lines.insert(0, '$ts  $line');
//     if (_lines.length > 100) {
//       _lines.removeRange(100, _lines.length);
//     }
//     notifyListeners();
//   }
//
//   void setSmartStatus(String status) {
//     smartStatus = status;
//     notifyListeners();
//   }
//
//   void clear() {
//     _lines.clear();
//     notifyListeners();
//   }
// }
