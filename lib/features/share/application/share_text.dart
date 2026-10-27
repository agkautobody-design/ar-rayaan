/// The fixed lines that end everything shared out of the app. Nothing here
/// builds a share: every share is built by `ShareService` from a `ShareDoc`
/// of public content, and ends with [shareFooter].
library;

/// Credit line that ends everything copied or shared out of the app.
const String kSharedFromLine = 'Shared from Ar-Rayaan';

/// The one address a share points to: the free web app. This is the single
/// place to change when store links exist. Fixed on purpose: a shared link
/// never carries a query, a referral code or anything about the sender.
const String kInviteUrl = 'https://ar-rayaan.onrender.com';

/// Says what the link is. Honest today: the app is free and works without an
/// account. Do not turn this into a call to create an account.
const String kShareDownloadLine = 'Free to use, no account needed';

/// The last block of every share: the credit, the download line, the link.
String shareFooter() => '$kSharedFromLine\n$kShareDownloadLine\n$kInviteUrl';
