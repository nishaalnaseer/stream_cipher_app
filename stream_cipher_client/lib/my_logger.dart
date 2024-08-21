// import 'dart:io';

import 'package:logger/logger.dart';

class QueueLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    return true;
  }
}

// class FileOutput extends LogOutput {
//   FileOutput();
//
//   File file;
//
//   @override
//   void init() {
//     super.init();
//     file = new File(filePath);
//   }
//
//   @override
//   void output(OutputEvent event) async {
//     if (file != null) {
//       for (var line in event.lines) {
//         await file.writeAsString("${line.toString()}\n",
//             mode: FileMode.writeOnlyAppend);
//       }
//     } else {
//       for (var line in event.lines) {
//         print(line);
//       }
//     }
//   }
// }


Logger logger = Logger(
    printer: PrettyPrinter(dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart),
    level: Level.all,
    filter: QueueLogFilter()
);