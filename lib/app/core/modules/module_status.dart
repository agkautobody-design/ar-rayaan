import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/content_sync.dart';

/// The registry law, in code: any surface that shows a module can ask for
/// its TRUE status (live / walled / unbuilt / gated) instead of assuming.
/// Unknown ids report 'unbuilt' — the honest default when the registry
/// cannot vouch for something.
class ModuleStatusService {
  ModuleStatusService(Map<String, dynamic> json)
      : _byId = <String, Map<String, dynamic>>{
          for (final dynamic m in (json['modules'] as List<dynamic>? ??
              const <dynamic>[]))
            (m as Map)['id'] as String: Map<String, dynamic>.from(m),
        };

  final Map<String, Map<String, dynamic>> _byId;

  String statusOf(String moduleId) =>
      (_byId[moduleId]?['status'] as String?) ?? 'unbuilt';

  bool isLive(String moduleId) => statusOf(moduleId) == 'live';
}

final moduleRegistryProvider =
    FutureProvider<ModuleStatusService>((Ref ref) async {
  final String raw = await ContentSync.load('system/module_registry.json');
  return ModuleStatusService(json.decode(raw) as Map<String, dynamic>);
});
