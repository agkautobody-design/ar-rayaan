/// The community rules and code of conduct shown before a person's first
/// post. Keep this in step with docs/product/community_rules_draft.md and with
/// kCommunityRulesVersion / backend COMMUNITY_RULES_VERSION: change the words
/// and the version moves with them, so everyone is asked to accept again.
///
/// DRAFT. The wording is the founder's list of principles put into plain
/// language. It has NOT been reviewed by the owner or by a scholar. Until it
/// has, [kCommunityRulesAreDraft] stays true and the screen says so.
const bool kCommunityRulesAreDraft = true;

class RulesSection {
  const RulesSection(this.title, this.points);
  final String title;
  final List<String> points;
}

const List<RulesSection> kCommunityRules = <RulesSection>[
  RulesSection('Who this is for', <String>[
    'The forums and meet-ups are for adults aged 18 and over. Children and '
        'teenagers never see them.',
    'Your display name is shown to other members. Do not use your full name, '
        'a phone number or an e-mail address.',
  ]),
  RulesSection('Community opinion, not a ruling', <String>[
    'Everything members write is their own opinion. It is not a fatwa and '
        'it is not religious guidance, and it is labelled that way.',
    'Please do not give rulings. If you need a ruling, use Ask a scholar: '
        'only verified scholars answer there, and their answers are labelled '
        'separately from the community.',
    'Hadi, the guide in this app, never reads or learns from community posts.',
  ]),
  RulesSection('Speak with adab', <String>[
    'Be kind. No insults, mockery, backbiting or name-calling.',
    'Disagree gently, and leave a discussion that is making you angry.',
    'No takfir: do not say that another Muslim is outside the faith.',
    'No fighting between schools of thought or groups. Sensitive topics '
        'have their own category and every post there is read by a moderator '
        'first.',
  ]),
  RulesSection('Keep people safe', <String>[
    'No photos. No home addresses, phone numbers or e-mail addresses, yours '
        'or anyone else’s.',
    'There are no private messages. Keep conversations here, in the open.',
    'Do not ask anyone to meet privately, or to move to another app.',
    'Do not share links to other sites unless a moderator has allowed the '
        'site. No advertising and no requests for money.',
  ]),
  RulesSection('Meet-ups', <String>[
    'Meet-ups are held only in public places: a mosque, a community centre, '
        'a library, a halal cafe, a park or a school hall. Never at a home.',
    'The organiser chooses who a meet-up is for: everyone, brothers, '
        'sisters, or families. Please respect that choice.',
    'A verified organiser has been checked by a person. An unverified '
        'organiser’s meet-up is read by a moderator before it appears.',
    'Children can only come to a families meet-up, with their parent or '
        'guardian signing them up. A child’s name is never shown.',
  ]),
  RulesSection('Report, hide, block', <String>[
    'You can report, hide or block anything or anyone, at any time, and the '
        'person will not be told it was you.',
    'If a child may be at risk, report it as such. It is hidden at once and '
        'a person looks at it first.',
  ]),
  RulesSection('What happens if rules are broken', <String>[
    'A moderator may hide a post, warn you, stop you posting for a while, '
        'or suspend your account. You are always told why.',
    'You can appeal any decision. A different moderator reads your appeal.',
    'You can export or delete your data at any time.',
  ]),
];
