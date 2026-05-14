// import 'package:flutter/material.dart';
//
// import '../example_log_controller.dart';
//
// class LogScreen extends StatelessWidget {
//   const LogScreen({super.key, required this.log});
//
//   final ExampleLogController log;
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         ListTile(
//           title: const Text('Event log'),
//           trailing: TextButton(
//             onPressed: log.clear,
//             child: const Text('Clear'),
//           ),
//         ),
//         Expanded(
//           child: ListenableBuilder(
//             listenable: log,
//             builder: (context, _) {
//               if (log.lines.isEmpty) {
//                 return const Center(child: Text('No events yet.'));
//               }
//               return ListView.builder(
//                 padding: const EdgeInsets.symmetric(horizontal: 12),
//                 itemCount: log.lines.length,
//                 itemBuilder: (context, i) {
//                   return SelectableText(
//                     log.lines[i],
//                     style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
//                   );
//                 },
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }
