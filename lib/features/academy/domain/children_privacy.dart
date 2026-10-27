/// The children's privacy text: ONE source for the consent step in the Family
/// Wing and for the "Children" section of the Privacy Policy.
///
/// Platform/legal: `kChildrenPrivacySection` is the text to place in the
/// Privacy Policy screen (it is deliberately written so it can be pasted
/// as-is). It states only what the app does today; if the behaviour changes
/// (for example parent accounts and cloud sync), change this text in the same
/// commit. It is a draft for legal review, not legal advice.
library;

/// Bump when the text changes in a way a parent must agree to again.
const int kChildrenPrivacyVersion = 6;

const String kChildrenPrivacyTitle = 'Children and the Family Wing';

/// Short version shown in the consent step.
const List<String> kChildrenPrivacyBullets = <String>[
  'The Family Wing is for parents and guardians. A parent adds a child; a child never needs an account.',
  'We store a first name or nickname you choose, an age band you choose (5-8, 9-12 or 13-17, so Wasia uses suitable words), and the child’s lesson and exam progress. Nothing else: no exact age, photo, voice, contact details or location.',
  'All of it stays on this device. It is not sent to our servers, to Firebase, or to any AI service. Wasia is never given a child’s name or progress.',
  'Questions a child asks Wasia are answered from the app’s own lessons. The AI service is off for children until you turn it on. If you do, the question the child types is sent, with no name, progress or profile. When a child asks from inside a lesson, the text of that lesson (the app’s own wording, which says nothing about the child) goes with the question, so the answer stays about the lesson. You can turn it off again.',
  'What you type as a parent into “Ask Wasia” in the Family Wing is your own question. If an AI key or subscription is set up, it may be sent to the AI service while the parent check is open, with no child’s name or progress.',
  'You can delete one child, or everything, at any time from the Family Wing. Deleting removes the name and all progress from this device straight away.',
  'Online game tables (Ludo and Shatranj, by a six-letter code) are OFF for every child until a parent switches them on, for that child, in the Family Wing. A table shows only “Player 1” and “Player 2”: no name, e-mail or profile is sent, and there is no chat. It is deleted when a player leaves and cannot be opened after six hours.',
  'There is no advertising, no tracking and no analytics about children in the app.',
];

/// The Privacy Policy section (plain text, paragraphs separated by a blank
/// line).
const String kChildrenPrivacyBody = '''
Ar-Rayaan is a general-audience app. It is not directed to children under 13 (or the age of digital consent where you live), and we do not knowingly collect personal information from a child. The Family Wing lets a parent or guardian set up learning profiles for the children in their care; the parent is the person who uses the app and who gives consent.

What a profile holds. For each child a parent adds, the app keeps on the device: a first name or nickname chosen by the parent (limited to 30 characters), an age band chosen by the parent (5-8, 9-12 or 13-17; it only decides which words Wasia uses and is never sent anywhere), the date the profile was created, and the child’s progress in the School of Letters (lessons finished, exam scores, mastery marks). We do not ask for or store a child’s exact age, date of birth, photo, voice, email address, phone number or location. Wasia sometimes asks a child how they are. The app keeps only the day it last asked and whether the child chose not to be asked again, on the device; the child’s answer is not kept. Wasia keeps no record of what a child says or how a child feels, a child’s conversation is a separate one from every other child’s and from the parent’s, and the parent dashboard never shows a child’s conversations or any safety message.

Where it is kept. Child profiles and progress are stored only on the device, in the app’s local storage. They are not sent to our servers or to any third party. A child’s name is never included in any request to an AI service or to Firebase. Cloud sync of family data is switched off; if we ever offer it, it will be optional, will need a parent’s separate consent first, and will never include a child’s name.

Wasia and AI services. When a child uses Wasia, answers come from the app’s own lesson content. The AI service is off for children by default. Only if a parent turns on “Ask the AI service for my child” is the question the child types sent to the AI service the app is connected to (the parent’s own key, or one managed with their subscription; for example Groq, OpenRouter or xAI). When the child asks from inside a lesson, the text of that lesson, which is the app’s own wording and says nothing about the child, is sent with the question. Nothing else is sent with it: no name, no lesson or exam progress, no profile data. Parents can turn this off at any time. Wasia is never given a child’s name or progress, in any mode. A parent’s own typed question in the Family Wing may be sent to the AI service while the parent check is open, again without a child’s name or progress.

Consent and parental controls. Before a first profile is created the parent confirms that they are the child’s parent or guardian and agrees to this section. Adding or removing a child, and the AI setting for children, sit behind a parent check. A parent can delete a single child or all children at any time; deletion removes the name and all progress from the device immediately, and withdraws the stored consent.

Retention. Profiles and progress are kept until the parent deletes them or the app is uninstalled, whichever comes first. Because the data is only on the device, we cannot retrieve it for you and do not hold a copy.

Online game tables. Ludo and Shatranj can be played against a friend on another device through a six-letter code. This is the one place where a child could reach a server, so it is switched off for every child by default and only a parent can switch it on, per child, behind the parent check in the Family Wing. When it is on, a table is a short-lived record on Google Firebase that holds the moves of the game and an anonymous sign-in number that Firebase gives the device (it is not linked to a name, e-mail address or profile). It holds no name, no child profile, no progress and no chat: the two seats are shown only as “Player 1” and “Player 2”. A table is deleted when a player leaves it, cannot be opened after six hours, and an automatic clean-up removes expired tables from the server. Anyone who has the six-letter code can join an open table, so a parent should share the code only with someone they know.

Advertising and analytics. The app contains no advertising and no analytics or crash-reporting service that receives information about children.

Contact. If you believe a child has given us personal information, or you have questions about this section, contact us using the address in the Terms and Privacy screens and we will help you delete it.
''';

/// Title + body, as shown in the consent step.
const String kChildrenPrivacySection =
    '$kChildrenPrivacyTitle\n\n$kChildrenPrivacyBody';
