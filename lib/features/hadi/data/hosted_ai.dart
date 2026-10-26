import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/packages/hadi_package.dart';
import '../../../app/core/packages/usage_meter.dart';
import '../application/hadi_provider.dart';
import 'groq_hadi_provider.dart' show HadiProviderException;
import 'hosted_cache.dart';

/// The hosted-AI seam for Hādi: answers out-of-library questions for people
/// on a package that allows it.
///
/// SECURITY CONTRACT (read before writing a real backend):
///  * The app holds NO provider key and NO secret. A real backend is a thin
///    HTTPS client to the owner's own server (a "proxy"). The proxy holds the
///    provider key, authenticates the user, applies the guardrail prompt,
///    and ENFORCES the package cap per user, per day and per month.
///  * The meter in the app (usage_meter.dart) is a display and a courtesy.
///    A client-side cap can be bypassed by clearing storage or patching the
///    app, so it must never be the only cap.
///  * When the proxy says the cap is reached it answers with
///    [HostedAiCapReached]; the app then falls back to the built-in library.
///
/// No real endpoint exists yet. [UnavailableHostedAi] is the default, so a
/// build without a backend behaves exactly as before.
abstract interface class HostedAi {
  /// False when no backend is configured; Hādi then never offers hosted AI.
  bool get isAvailable;

  /// Answer [request]. Throws [HostedAiCapReached] when the server's cap for
  /// this user is spent, or [HadiProviderException] for any other failure.
  Future<HostedAiReply> ask(HostedAiRequest request);
}

class HostedAiRequest {
  const HostedAiRequest({
    required this.question,
    required this.history,
    required this.package,
    required this.maxReplyChars,
    this.maxOutputTokens = kHostedMaxOutputTokens,
    this.preferSmallModel = kHostedSmallModelFirst,
  });

  /// The question with the app's grounding context already attached.
  final String question;
  final List<HadiMessage> history;

  /// Package id ('free' | 'plus' | 'family') so the server can apply its cap.
  /// The server must verify entitlement itself, never trust this field.
  final String package;

  /// A hint for the server; the app also shortens a longer reply.
  final int maxReplyChars;

  /// Hard cap on the reply the model may write (cost control).
  final int maxOutputTokens;

  /// Small-model-first policy: the server should try its small, cheap model
  /// and only escalate when it must. The app never names a model.
  final bool preferSmallModel;
}

class HostedAiReply {
  const HostedAiReply(this.text);
  final String text;
}

/// The server refused because this user's cap is spent.
class HostedAiCapReached extends HadiProviderException {
  const HostedAiCapReached([
    super.message = 'The AI allowance for now is used up.',
  ]);
}

/// Default: no backend. Hosted AI is not offered anywhere in the app.
class UnavailableHostedAi implements HostedAi {
  const UnavailableHostedAi();

  @override
  bool get isAvailable => false;

  @override
  Future<HostedAiReply> ask(HostedAiRequest request) {
    throw const HadiProviderException(
      'Hosted AI is not available in this version.',
    );
  }
}

/// TODO-OWNER: replace with the real proxy client once a server and provider
/// exist. Override this provider; no other code changes.
final Provider<HostedAi> hostedAiProvider =
    Provider<HostedAi>((ref) => const UnavailableHostedAi());

/// The label every hosted answer carries, in the reply itself so it survives
/// saving and restoring the conversation.
const String kHostedAiLabel =
    'AI-generated, may be wrong. Check with a scholar.';

/// Extra rules sent with every hosted question, on top of Hādi's own prompt.
const String kHostedAiScopeRules =
    'This answer comes from a hosted model, outside the app\'s checked '
    'library. Give general information only. Do not issue a fatwa or rule on '
    'the user\'s own case. Do not give medical or legal advice: send them to '
    'a doctor, a lawyer or a qualified scholar. If the user may be in danger '
    'or distress, do not answer from knowledge: tell them to contact their '
    'local emergency number or a crisis line.\n';

/// Shortens [text] to at most [max] characters at a sentence end where one
/// exists, otherwise at a word. Never cuts a [[src:]] token in half.
String limitReply(String text, int max) {
  if (max <= 0 || text.length <= max) return text;
  String cut = text.substring(0, max);
  // Do not leave half an ID token.
  final int open = cut.lastIndexOf('[[');
  if (open != -1 && cut.indexOf(']]', open) == -1) cut = cut.substring(0, open);
  int end = -1;
  for (final String m in <String>['. ', '! ', '? ', '.\n']) {
    final int i = cut.lastIndexOf(m);
    if (i > end) end = i;
  }
  if (end > max ~/ 3) return cut.substring(0, end + 1).trimRight();
  final int sp = cut.lastIndexOf(' ');
  return '${(sp > 0 ? cut.substring(0, sp) : cut).trimRight()}...';
}

/// Cost controls for the hosted path.
const int kHostedMaxOutputTokens = 350;
const int kHostedMaxHistory = 4;
const int kHostedMaxQuestionChars = 500;
const int kHostedMaxPassages = 2;

/// Small-model-first policy flag (sent to the server as a hint).
const bool kHostedSmallModelFirst = true;

/// Hosted AI is for Islam-related questions only. Anything with no Islamic
/// or app word in it is out of scope and never costs a call (the library's
/// polite refusal is shown instead).
bool isHostedScope(String question) => RegExp(
      r'\b(?:allah|islam\w*|muslims?|quran\w*|qur.an|surah|ayah|ayat|verse|'
      r'hadiths?|sunnah|sunan|prophets?|rasul|messenger|muhammad|sahaba|'
      r'companions?|seerah|sirah|caliph\w*|imam|shaykh|sheikh|scholar|fiqh|'
      r'madhhab|dua|duas|dhikr|adhkar|salah|salat|prayers?|pray|wudu|ghusl|'
      r'tayammum|fast|fasting|ramadan|eid|zakat|zakah|sadaqah|hajj|umrah|'
      r'kaaba|makkah|mecca|madinah|medina|masjid|mosque|halal|haram|jannah|'
      r'paradise|hell|jahannam|angels?|jinn|shaytan|satan|iblis|akhirah|'
      r'qiyamah|judgment|tawheed|tawhid|shirk|iman|taqwa|sabr|tawbah|'
      r'repent\w*|nikah|hijab|khutbah|jumu.?ah|jummah|adhan|azan|qibla|'
      r'sujood|ruku|rakah|rakat|tasbeeh|istighfar|barakah|ummah|dawah|'
      r'revert|convert|shahada|shahadah|arabic|adam|ibrahim|abraham|musa|'
      r'moses|isa|jesus|yusuf|joseph|nuh|noah|maryam|mary|dawud|sulaiman)\b',
      caseSensitive: false,
    ).hasMatch(question);

/// True for a question that asks what is permitted, forbidden or required.
/// Those go to a scholar, never to a hosted model, even when the library has
/// no entry (the library says so and points to Our Sources).
bool isRulingShaped(String question) => RegExp(
      r'\b(?:halal|haram|permissible|permitted|allowed|forbidden|prohibited|'
      r'lawful|unlawful|makruh|mustahabb?|wajib|fard|fatwa|fatwah|ruling|'
      r'sin|sinful|obligatory|valid|invalid|can i|may i|should i|must i|'
      r'am i allowed|do i have to)\b',
      caseSensitive: false,
    ).hasMatch(question);

/// Adapts a [HostedAi] backend to the provider contract the controller
/// already uses, so a hosted reply goes through the same checks (reference
/// verifier, ruling filter) as any live reply.
///
/// Cost order: a saved answer for the same question first (no call, nothing
/// counted), then the backend with a short request (last few messages only,
/// hard token cap, small-model-first hint). A failed call gives the count
/// back and saves nothing.
class HostedHadiProvider implements HadiProvider {
  HostedHadiProvider({
    required this.backend,
    required this.meter,
    required this.package,
    required this.limits,
    this.cache,
    this.cacheKey = '',
  });

  final HostedAi backend;
  final UsageMeter meter;
  final HadiPackage package;
  final HadiPackageLimits limits;
  final HostedAnswerCache? cache;

  /// Normalised question (plus anything that changes the answer, such as the
  /// school of law). Empty means: do not cache this one.
  final String cacheKey;

  /// True when the last [ask] was served from the saved answers.
  bool servedFromCache = false;

  @override
  Future<String> ask(String question, List<HadiMessage> history) async {
    servedFromCache = false;
    final String? saved = cache?.get(cacheKey);
    if (saved != null) {
      servedFromCache = true;
      return saved;
    }
    if (!await meter.tryConsume(limits)) {
      throw const HostedAiCapReached();
    }
    try {
      final HostedAiReply r = await backend.ask(
        HostedAiRequest(
          question: question,
          history: history.length > kHostedMaxHistory
              ? history.sublist(history.length - kHostedMaxHistory)
              : history,
          package: package.name,
          maxReplyChars: limits.maxReplyChars,
        ),
      );
      await cache?.put(cacheKey, r.text);
      return r.text;
    } catch (_) {
      await meter.refund();
      rethrow;
    }
  }
}
