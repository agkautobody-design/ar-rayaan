/// Who is making sound right now, so two voices never play over each other.
///
/// Whoever starts (the read-aloud narrator or the Qur'an recitation) sets the
/// claim; everything else that is playing stops or pauses. Pure state: it
/// touches no audio itself, so tests and screens that never play are
/// unaffected.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum VoiceSource { none, narrator, recitation }

class VoiceClaim {
  const VoiceClaim(this.source, this.serial);

  final VoiceSource source;

  /// Distinct for every claim, so a source claiming twice still notifies.
  final int serial;
}

int _serial = 0;

final StateProvider<VoiceClaim> voiceClaimProvider =
    StateProvider<VoiceClaim>((Ref ref) => const VoiceClaim(VoiceSource.none, 0));

/// Makes [source] the one that is speaking.
void claimVoice(Ref ref, VoiceSource source) {
  ref.read(voiceClaimProvider.notifier).state = VoiceClaim(source, ++_serial);
}
