# Children's privacy: age band per child (for the privacy lawyer)

Status: draft, needs a lawyer. Raised by the Hadi + Wasia support module, Phase 2.

What changed in the app (children's privacy version 4 -> 5, parents re-consent):
- A parent can set an age band for each child: 5-8, 9-12 or 13-17. It is stored on the device only (`ar.family.age_band.<childId>`), is removed when the child is deleted, and is never sent to any service. It only chooses which words Wasia uses with that child.
- Wasia keeps no record of what a child says or how a child feels. The parent dashboard never shows a child's conversations or any safety message.
- A child's support conversation is never sent to an online model, never saved, and never reportable.

Questions for the lawyer:
1. Does storing an age band (not a date of birth) change the "we do not knowingly collect personal information from a child" position under COPPA / UK AADC / GDPR-K?
2. Is the re-consent wording in `lib/features/academy/domain/children_privacy.dart` enough, and is "parent or guardian" confirmation still valid?
3. Is it acceptable that the app shows a child a child helpline without the parent's knowledge? (Intended: yes, so a child is not sent back to the person who may be harming them.)
4. Mandatory reporting: the app cannot report; it says so. Is any extra wording needed per jurisdiction?
5. Key storage: the AI key and opt-in memory sit in the platform secure store (phone) or memory only (web).
