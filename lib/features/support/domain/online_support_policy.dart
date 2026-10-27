/// When, and only when, a support chat may use the online model.
///
/// Off by default. Even when the person turned it on, a model is NEVER used:
///  * with the person's own third-party key (a free-tier key has unknown
///    retention terms): only a key managed for them by the app's subscription;
///  * after a crisis card, while the conversation is latched, for a child or
///    someone who said they are under 18, or for a message that looks like an
///    emergency, abuse or self-harm (crisis detection runs on the device
///    first, always);
///  * for fixed wording (safety, referral) or a medical question.
/// The reply that comes back is checked; if it fails any check the on-device
/// reply is used instead.
abstract final class SupportOnlinePolicy {
  static bool allowed({
    required bool setting,
    required bool usingManagedKey,
    required bool hasManagedKey,
    required bool crisis,
    required bool latched,
    required bool minor,
    required bool fixedWording,
  }) =>
      setting &&
      usingManagedKey &&
      hasManagedKey &&
      !crisis &&
      !latched &&
      !minor &&
      !fixedWording;

  static const String systemPrompt =
      'You are Hadi, a calm companion inside an Islamic app, talking with an adult '
      'who may be struggling with a habit, an addiction, or something at home. '
      'You are an app, not a person, a doctor, a counsellor or a scholar; never '
      'say otherwise and never say you feel or understand as a person does.\n'
      'Rules, all of them:\n'
      '1. Reply in 60 words or fewer, in plain warm language, with at most ONE question.\n'
      '2. Reflect what they said first. Do not lecture, do not moralise, do not '
      'say haram, sin or forbidden, and do not give a ruling or a fatwa.\n'
      '3. Never give a dose, an amount, a taper, a schedule, a drug name to take, '
      'a diagnosis, or a label for the person (never "addict" or "alcoholic").\n'
      '4. Never promise secrecy. Never agree to hide something from a doctor or family.\n'
      '5. Offer, never push. If it fits, suggest one trusted person or a doctor.\n'
      '6. Do not quote the Qur’an or hadith. Do not invent phone numbers.\n'
      '7. Do not end with a stock closer such as "Does that help?".';

  static final RegExp _dose = RegExp(
      r'\b\d+\s?(mg|ml|pills?|tablets?|units?|drinks?|grams?)\b',
      caseSensitive: false);
  static final RegExp _lecture = RegExp(
      r'\b(haram|forbidden|sinful|you failed|filthy|disgusting|addicted|alcoholic|addict|fatwa)\b',
      caseSensitive: false);
  static final RegExp _human = RegExp(
      r"\b(i am (a )?(human|person|therapist|counsellor|counselor|doctor|scholar)|i feel your pain|i understand exactly)\b",
      caseSensitive: false);
  static final RegExp _secrecy = RegExp(r"(i promise|our secret|no one will ever know|keep (this|it) secret)",
      caseSensitive: false);
  static final RegExp _digits = RegExp(r'\d{3,}');

  /// Whether a model's [answer] may be shown.
  static bool acceptable(String answer) {
    final String a = answer.trim();
    if (a.isEmpty) return false;
    if (a.split(RegExp(r'\s+')).length > 90) return false;
    if ('?'.allMatches(a).length > 1) return false;
    if (_dose.hasMatch(a) || _lecture.hasMatch(a) || _human.hasMatch(a) || _secrecy.hasMatch(a)) return false;
    if (_digits.hasMatch(a)) return false;
    if (RegExp(r'does that help\??\s*$', caseSensitive: false).hasMatch(a)) return false;
    return true;
  }
}
