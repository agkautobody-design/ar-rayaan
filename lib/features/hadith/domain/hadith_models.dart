/// Hadith domain models.
///
/// v1 bundled content: The Forty Hadith of Imam an-Nawawi (Arabic +
/// English, fawazahmed0 verified editions). See Build Sheet v1.6:
/// Riyad as-Salihin (O-5) could not be sourced from this environment
/// (dataset paths 404, sunnah.com Cloudflare-blocked); an-Nawawi is the
/// same author and Riyad opens with this same first hadith. Swap is a
/// data-file change only — screens/providers untouched.
class Hadith {
  const Hadith({
    required this.number,
    required this.arabic,
    required this.english,
  });

  final int number;
  final String arabic;
  final String english;
}
