import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

import 'package:vmlogger/vmlogger.dart';

void main() {
  test('test message', () {
    Logger.root.level = Level.INFO;
    Logger.root.onRecord.listen(formatEntry);
  });
}
