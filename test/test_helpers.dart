import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wrap a widget with the app theme + ProviderScope whose
/// sharedPreferencesProvider is the mocked instance.
///
/// Tests call `SharedPreferences.setMockInitialValues({})` in setUp;
/// getInstance() then returns the in-memory mock, which we inject.
/// Every prefs-touching provider (progress, word deck, flags) resolves
/// through this override.
Future<Widget> wrapWithProviders(Widget child) async {
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: <Override>[
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: MaterialApp(theme: AppTheme.dark(), home: child),
  );
}
