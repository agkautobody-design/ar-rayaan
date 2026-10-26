/// Which translation the reader shows, and the packs that can be chosen.
///
/// The default English translation is The Clear Quran (Dr. Mustafa Khattab).
/// Its text is a licensed pack that is added as a data file; until that file
/// is present and valid the reader shows the interim translation and every
/// credit says so. Choosing another language works the same way.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';
import '../data/translation_pack_loader.dart';
import '../domain/translation_pack.dart';

SharedPreferences? _prefsOrNull(Ref<Object?> ref) {
  try {
    return ref.read(sharedPreferencesProvider);
  } catch (_) {
    return null;
  }
}

final Provider<TranslationPackLoader> translationPackLoaderProvider =
    Provider<TranslationPackLoader>(
      (ref) => TranslationPackLoader(
        store: DeviceTranslationPackStore(_prefsOrNull(ref)),
      ),
    );

/// The translation id the person chose, or null for the default.
class TranslationSelectionController extends Notifier<String?> {
  static const String prefsKey = 'ar.quran.translationId';

  @override
  String? build() {
    try {
      final String? v = _prefsOrNull(ref)?.getString(prefsKey);
      if (v != null && v.isNotEmpty) return v;
    } catch (_) {
      // No storage: the default.
    }
    return null;
  }

  /// [id] null returns to the default.
  Future<void> choose(String? id) async {
    state = id;
    try {
      final SharedPreferences? p = _prefsOrNull(ref);
      if (id == null) {
        await p?.remove(prefsKey);
      } else {
        await p?.setString(prefsKey, id);
      }
    } catch (_) {
      // Session only.
    }
  }
}

final NotifierProvider<TranslationSelectionController, String?>
translationSelectionProvider =
    NotifierProvider<TranslationSelectionController, String?>(
      TranslationSelectionController.new,
    );

/// The translation in use right now.
final FutureProvider<ActiveTranslation> activeTranslationProvider =
    FutureProvider<ActiveTranslation>((ref) async {
      final String wanted =
          ref.watch(translationSelectionProvider) ??
          kDefaultTranslationByLanguage['en']!;
      if (wanted == kInterimEnglishId) {
        return ActiveTranslation(wantedId: wanted, pack: null);
      }
      TranslationPack? pack;
      try {
        pack = await ref.read(translationPackLoaderProvider).load(wanted);
      } catch (_) {
        pack = null;
      }
      return ActiveTranslation(wantedId: wanted, pack: pack);
    });

/// Packs that can be chosen (bundled with a granted licence, or downloaded).
final FutureProvider<List<TranslationChoice>> availableTranslationsProvider =
    FutureProvider<List<TranslationChoice>>(
      (ref) => ref.read(translationPackLoaderProvider).available(),
    );

/// True when the translation in use reads right to left (Urdu, Arabic).
final Provider<bool> translationRtlProvider = Provider<bool>(
  (ref) =>
      ref.watch(activeTranslationProvider).valueOrNull?.rtl ?? false,
);
