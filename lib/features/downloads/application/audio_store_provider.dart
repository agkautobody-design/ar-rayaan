import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/audio_file_store.dart';
import '../data/audio_file_store_platform.dart';

/// The recitation store for this platform. Tests override it with a fake.
final Provider<AudioFileStore> audioFileStoreProvider =
    Provider<AudioFileStore>((Ref ref) => createPlatformAudioStore());
