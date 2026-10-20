import 'dart:io';

/// Reads lib/app/router.dart as text and returns the route paths it declares.
///
/// The router is plain Dart with no code generation, so its `GoRoute(path:`
/// declarations can be read straight from the source. Constants declared on
/// `AppRoutes` (`static const String x = '/x'`) and `${AppRoutes.x}` string
/// interpolations are resolved. Child routes with a relative path (no leading
/// slash) are returned as written.
class RouterSource {
  RouterSource._(this.source, this.constants, this.paths, this.founderOnly);

  factory RouterSource.read() {
    final String source = File('lib/app/router.dart').readAsStringSync();
    final Map<String, String> constants = <String, String>{
      for (final RegExpMatch m in RegExp(
        r"static const String (\w+)\s*=\s*'([^']+)'",
      ).allMatches(source))
        m.group(1)!: m.group(2)!,
    };

    String resolve(String raw) => raw.replaceAllMapped(
          RegExp(r'\$\{AppRoutes\.(\w+)\}'),
          (Match m) => constants[m.group(1)!] ?? '?${m.group(1)}?',
        );

    final List<String> paths = <String>[];
    for (final RegExpMatch m in RegExp(
      r"path:\s*(?:'([^']+)'|AppRoutes\.(\w+))",
    ).allMatches(source)) {
      final String? literal = m.group(1);
      if (literal != null) {
        paths.add(resolve(literal));
      } else {
        paths.add(constants[m.group(2)!] ?? '?${m.group(2)}?');
      }
    }

    final Set<String> founderOnly = <String>{};
    for (final RegExpMatch m in RegExp(
      r"if \(kFounderTools\)\s*GoRoute\(\s*path:\s*(?:'([^']+)'|AppRoutes\.(\w+))",
    ).allMatches(source)) {
      final String? literal = m.group(1);
      founderOnly.add(
        literal != null ? resolve(literal) : constants[m.group(2)!] ?? '',
      );
    }
    return RouterSource._(source, constants, paths, founderOnly);
  }

  final String source;

  /// `AppRoutes` string constants by name.
  final Map<String, String> constants;

  /// Every declared path, in source order, duplicates kept.
  final List<String> paths;

  /// Paths that only exist when `kFounderTools` is true.
  final Set<String> founderOnly;

  /// Absolute paths only (child routes excluded).
  List<String> get absolutePaths =>
      paths.where((String p) => p.startsWith('/')).toList();

  /// True when [link] is matched by a declared path, treating `:param`
  /// segments as wildcards.
  bool resolves(String link) {
    final String p = link.split('?').first;
    for (final String q in absolutePaths) {
      if (q == p) return true;
      if (q.contains(':')) {
        final RegExp rx =
            RegExp('^${q.replaceAll(RegExp(r':\w+'), r'[^/]+')}\$');
        if (rx.hasMatch(p)) return true;
      }
    }
    return false;
  }
}
