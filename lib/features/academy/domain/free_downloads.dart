/// Recordings a person may download for themselves from the source's own
/// page. Ar-Rayaan does not host, copy or re-serve any of them: the app only
/// names each recording, says what its source states about use, and opens the
/// source's own page, where the person downloads their own copy.
///
/// Every entry was read on its source page; [terms] repeats what that page
/// says and nothing more. Titles and artists are as the source gives them.
library;

class FreeDownload {
  const FreeDownload({
    required this.id,
    required this.title,
    required this.by,
    required this.source,
    required this.pageUrl,
    required this.terms,
    required this.credit,
  });

  final String id;
  final String title;
  final String by;

  /// Name of the site that offers the download.
  final String source;

  /// The source's own page for this recording (https, an allowed host).
  final String pageUrl;

  /// What the source says about use, in its own words, shortened.
  final String terms;

  /// The credit line to keep with the file when the terms ask for credit.
  final String credit;
}

/// Hosts a download link may point to. Anything else is a bug.
const Set<String> kFreeDownloadHosts = <String>{
  'makkahlive.net',
  'freemusicarchive.org',
};

const List<FreeDownload> kFreeDownloads = <FreeDownload>[
  FreeDownload(
    id: 'mk-eid-takbeer',
    title: 'Eid Takbeer (Allahu Akbar, La ilaha illallah)',
    by: 'Beautiful Voice Recitation',
    source: 'Makkah Live',
    pageUrl: 'https://makkahlive.net/en/audio/eid-takbeer',
    terms: 'Makkah Live says its recordings are free to listen to and '
        'download for personal use, and not for commercial use.',
    credit: '',
  ),
  FreeDownload(
    id: 'mk-subhanallah',
    title: 'Subhanallah wa Bihamdihi (dhikr nasheed)',
    by: 'Beautiful Voice',
    source: 'Makkah Live',
    pageUrl: 'https://makkahlive.net/en/audio/subhanallah-wa-bihamdihi',
    terms: 'Makkah Live says its recordings are free to listen to and '
        'download for personal use, and not for commercial use.',
    credit: '',
  ),
  FreeDownload(
    id: 'mk-do-you-know-islam',
    title: 'Do You Know What Islam Is (educational nasheed)',
    by: 'Various',
    source: 'Makkah Live',
    pageUrl: 'https://makkahlive.net/en/audio/do-you-know-islam',
    terms: 'The page says: free to listen and download for personal or '
        'educational use.',
    credit: '',
  ),
  FreeDownload(
    id: 'fma-el-safti-ala-fi-sabil-allah',
    title: 'Ala fi Sabil Allah (a classical Arabic qasida)',
    by: 'Sheikh Sayed El-Safti, recorded between about 1907 and 1925',
    source: 'Free Music Archive',
    pageUrl:
        'https://freemusicarchive.org/music/Sheikh_Sayed_El-Safti/single/Ala_fi_Sabil_Allah',
    terms: 'Licence: Creative Commons Attribution-NonCommercial (BY-NC). '
        'Keep the credit, and use it for yourself, not to sell or earn from it.',
    credit: 'Sheikh Sayed El-Safti, "Ala fi Sabil Allah", via Free Music '
        'Archive (CC BY-NC)',
  ),
];
