/// Doctor providers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'vitals_registry.dart';

final heartbeatLogProvider = Provider<HeartbeatLog>((Ref ref) {
  final log = HeartbeatLog();
  ref.onDispose(log.dispose);
  return log;
});
