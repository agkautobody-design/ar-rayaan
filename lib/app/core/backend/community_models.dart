part of 'models.dart';

// Forums, meet-ups, notifications and moderation (community phase 2). These
// follow backend/src/{forums,meetups,notifications,moderation}.ts exactly.

/// `communityCentre` -> `community_centre`.
String _snake(String camel) => camel.replaceAllMapped(
  RegExp('[A-Z]'),
  (Match m) => '_${m.group(0)!.toLowerCase()}',
);

/// community_opinion is the default and is always shown with that label.
/// scholar_answer is only accepted from a verified scholar. Community content
/// is never religious guidance and is never given to Hadi as such.
enum ForumLabel { communityOpinion, scholarAnswer, question, announcement }

enum ForumCategoryKind {
  general,
  learning,
  askScholar,
  sensitive,
  family,
  announcements,
  wellbeing,
}

/// The rules acceptance state (`GET /v1/community/rules`).
class CommunityRulesStatus {
  const CommunityRulesStatus({
    required this.version,
    required this.accepted,
    required this.hasProfile,
    required this.communityVisible,
    this.mutedUntil,
  });

  factory CommunityRulesStatus.fromJson(Map<String, dynamic> j) =>
      CommunityRulesStatus(
        version: _str(j, 'version'),
        accepted: _bool(j, 'accepted'),
        hasProfile: _bool(j, 'hasProfile'),
        communityVisible: _bool(j, 'communityVisible'),
        mutedUntil: _strOrNull(j, 'mutedUntil'),
      );

  final String version;
  final bool accepted;
  final bool hasProfile;

  /// The profile is set to show its display name in the community.
  final bool communityVisible;

  /// An ISO time, `indefinite`, or null.
  final String? mutedUntil;

  /// True when this person may write: a profile, shown in the community,
  /// rules accepted, not muted.
  bool get canWrite =>
      hasProfile && communityVisible && accepted && mutedUntil == null;
}

class ForumCategory {
  const ForumCategory({
    required this.id,
    required this.slug,
    required this.title,
    required this.kind,
    required this.strictModeration,
    this.description = '',
    this.rulesNote = '',
    this.canStart = false,
    this.canReply = false,
    this.threadCount = 0,
  });

  factory ForumCategory.fromJson(Map<String, dynamic> j) => ForumCategory(
    id: _str(j, 'id'),
    slug: _str(j, 'slug'),
    title: _str(j, 'title'),
    description: _strOrNull(j, 'description') ?? '',
    rulesNote: _strOrNull(j, 'rulesNote') ?? '',
    kind: _enum(
      ForumCategoryKind.values,
      _camel(_strOrNull(j, 'kind')),
      ForumCategoryKind.general,
    ),
    strictModeration: _bool(j, 'strictModeration'),
    canStart: _bool(j, 'canStart'),
    canReply: _bool(j, 'canReply'),
    threadCount: _int(j, 'threadCount'),
  );

  final String id;
  final String slug;
  final String title;
  final String description;
  final String rulesNote;
  final ForumCategoryKind kind;

  /// Every post waits for a moderator before it appears.
  final bool strictModeration;
  final bool canStart;
  final bool canReply;
  final int threadCount;

  bool get isAskScholar => kind == ForumCategoryKind.askScholar;
}

class ForumThread {
  const ForumThread({
    required this.id,
    required this.categoryId,
    required this.categorySlug,
    required this.title,
    required this.authorName,
    required this.postCount,
    required this.createdAt,
    required this.lastPostAt,
    this.authorProfileId,
    this.pinned = false,
    this.locked = false,
    this.pendingReview = false,
    this.answered = false,
    this.mine = false,
  });

  factory ForumThread.fromJson(Map<String, dynamic> j) => ForumThread(
    id: _str(j, 'id'),
    categoryId: _str(j, 'categoryId'),
    categorySlug: _strOrNull(j, 'categorySlug') ?? '',
    title: _str(j, 'title'),
    authorName: _strOrNull(j, 'authorName') ?? '',
    authorProfileId: _strOrNull(j, 'authorProfileId'),
    postCount: _int(j, 'postCount'),
    createdAt: _time(j, 'createdAt'),
    lastPostAt: _time(j, 'lastPostAt'),
    pinned: _bool(j, 'pinned'),
    locked: _bool(j, 'locked'),
    pendingReview: _bool(j, 'pendingReview'),
    answered: _bool(j, 'answered'),
    mine: _bool(j, 'mine'),
  );

  final String id;
  final String categoryId;
  final String categorySlug;
  final String title;
  final String authorName;
  final String? authorProfileId;
  final int postCount;
  final DateTime createdAt;
  final DateTime lastPostAt;
  final bool pinned;
  final bool locked;

  /// Waiting for a moderator; only its author can see it.
  final bool pendingReview;

  /// A verified scholar has answered (Ask a scholar).
  final bool answered;
  final bool mine;
}

class ThreadList {
  const ThreadList({required this.threads, required this.hasMore});

  factory ThreadList.fromJson(Map<String, dynamic> j) => ThreadList(
    threads: _list(j['threads']).map(ForumThread.fromJson).toList(),
    hasMore: _bool(j, 'hasMore'),
  );

  final List<ForumThread> threads;
  final bool hasMore;
}

class ForumPost {
  const ForumPost({
    required this.id,
    required this.threadId,
    required this.label,
    required this.createdAt,
    required this.status,
    this.authorName = '',
    this.authorProfileId,
    this.body = '',
    this.replyTo,
    this.editedAt,
    this.helpfulByMe = false,
    this.helpfulCount,
    this.scholarOrg,
    this.mine = false,
  });

  factory ForumPost.fromJson(Map<String, dynamic> j) => ForumPost(
    id: _str(j, 'id'),
    threadId: _str(j, 'threadId'),
    replyTo: _strOrNull(j, 'replyTo'),
    authorName: _strOrNull(j, 'authorName') ?? '',
    authorProfileId: _strOrNull(j, 'authorProfileId'),
    body: _strOrNull(j, 'body') ?? '',
    label: _enum(
      ForumLabel.values,
      _camel(_strOrNull(j, 'label')),
      ForumLabel.communityOpinion,
    ),
    status: _strOrNull(j, 'status') ?? 'visible',
    createdAt: _time(j, 'createdAt'),
    editedAt: _timeOrNull(j, 'editedAt'),
    helpfulByMe: _bool(j, 'helpfulByMe'),
    helpfulCount: j['helpfulCount'] is num
        ? (j['helpfulCount'] as num).toInt()
        : null,
    scholarOrg: _strOrNull(j, 'scholarOrg'),
    mine: _bool(j, 'mine'),
  );

  final String id;
  final String threadId;
  final String? replyTo;
  final String authorName;
  final String? authorProfileId;
  final String body;
  final ForumLabel label;

  /// visible, pending_review, hidden, removed or hidden_by_you.
  final String status;
  final DateTime createdAt;
  final DateTime? editedAt;
  final bool helpfulByMe;

  /// Only the author is told the count (encouragement, not a score).
  final int? helpfulCount;

  /// The organisation a verified scholar answers for, when they gave one.
  final String? scholarOrg;
  final bool mine;

  bool get pendingReview => status == 'pending_review';

  /// A hidden or removed post comes back with no text.
  bool get isPlaceholder =>
      status == 'hidden' || status == 'removed' || status == 'hidden_by_you';
}

class ThreadView {
  const ThreadView({
    required this.thread,
    required this.posts,
    required this.hasMore,
    this.next,
  });

  factory ThreadView.fromJson(Map<String, dynamic> j) => ThreadView(
    thread: ForumThread.fromJson(_map(j['thread'])),
    posts: _list(j['posts']).map(ForumPost.fromJson).toList(),
    hasMore: _bool(j, 'hasMore'),
    next: _strOrNull(j, 'next'),
  );

  final ForumThread thread;
  final List<ForumPost> posts;
  final bool hasMore;
  final String? next;
}

/// What the server says after a thread or reply is submitted.
class SubmitResult {
  const SubmitResult({
    required this.pendingReview,
    required this.showHelp,
    this.threadId,
    this.postId,
  });

  /// From `POST .../threads`.
  factory SubmitResult.fromThreadJson(Map<String, dynamic> j) => SubmitResult(
    threadId: _str(_map(j['thread']), 'id'),
    postId: _strOrNull(j, 'postId'),
    pendingReview: _bool(j, 'pendingReview'),
    showHelp: _bool(j, 'showHelp'),
  );

  /// From `POST .../posts` and `PATCH /v1/forum/posts/:id`.
  factory SubmitResult.fromPostJson(Map<String, dynamic> j) {
    final Map<String, dynamic> p = _map(j['post']);
    return SubmitResult(
      threadId: _strOrNull(p, 'threadId'),
      postId: _str(p, 'id'),
      pendingReview: _bool(j, 'pendingReview'),
      showHelp: _bool(j, 'showHelp'),
    );
  }

  final String? threadId;
  final String? postId;

  /// A moderator reads it before anyone else sees it.
  final bool pendingReview;

  /// Show gentle help-line wording (the text suggested the writer may be
  /// struggling). Never shown as a warning against the writer.
  final bool showHelp;
}

/// Why something is reported. Wire names are the server's.
enum ReportReason {
  abuse('abuse', 'Abuse or bullying'),
  harassment('harassment', 'Harassment'),
  hate('hate', 'Hatred toward a group'),
  sectarian('sectarian', 'Sectarian fighting or takfir'),
  religiousMisinformation(
    'religious_misinformation',
    'A ruling given as if it were certain',
  ),
  sexual('sexual', 'Sexual or indecent content'),
  childSafety('child_safety', 'A child may be at risk'),
  spam('spam', 'Spam or advertising'),
  privacy('privacy', 'Private information or a home address'),
  scam('scam', 'Scam or money request'),
  other('other', 'Something else');

  const ReportReason(this.wire, this.label);
  final String wire;
  final String label;
}

/// What can be reported, hidden for me, or blocked.
enum CommunityTarget { post, thread, profile, meetup }

/// Why an organiser cancels. Attendees are told the reason.
enum CancelReason {
  weather('weather', 'Weather'),
  venueUnavailable('venue_unavailable', 'The venue is not available'),
  lowAttendance('low_attendance', 'Too few people'),
  organiserUnavailable('organiser_unavailable', 'I can no longer organise it'),
  other('other', 'Another reason');

  const CancelReason(this.wire, this.label);
  final String wire;
  final String label;
}

class MeetupOrganiser {
  const MeetupOrganiser({
    required this.profileId,
    required this.displayName,
    required this.verified,
    this.orgName,
  });

  factory MeetupOrganiser.fromJson(Map<String, dynamic> j) => MeetupOrganiser(
    profileId: _str(j, 'profileId'),
    displayName: _str(j, 'displayName'),
    verified: _bool(j, 'verified'),
    orgName: _strOrNull(j, 'orgName'),
  );

  final String profileId;
  final String displayName;

  /// A human checked this organiser (for example with the mosque).
  final bool verified;
  final String? orgName;
}

enum MeetupAudience { open, brothers, sisters, families }

/// Only public venues. There is no field for a private address.
enum MeetupVenueKind {
  mosque,
  communityCentre,
  library,
  cafe,
  park,
  schoolHall,
  otherPublic,
}

enum MeetupRecurrence { none, weekly, biweekly, monthly }

class Meetup {
  const Meetup({
    required this.id,
    required this.title,
    required this.venueKind,
    required this.venueName,
    required this.city,
    required this.country,
    required this.startsAt,
    required this.audience,
    required this.guardianRsvpForMinors,
    required this.organiser,
    this.description = '',
    this.venueAddress,
    this.region,
    this.endsAt,
    this.capacity,
    this.spotsLeft,
    this.goingCount = 0,
    this.waitlistCount = 0,
    this.accessibilityNotes,
    this.halalConfirmed = false,
    this.status = 'published',
    this.recurrence = MeetupRecurrence.none,
    this.cancelReason,
    this.mine = false,
    this.myRsvp,
  });

  factory Meetup.fromJson(Map<String, dynamic> j) => Meetup(
    id: _str(j, 'id'),
    title: _str(j, 'title'),
    description: _strOrNull(j, 'description') ?? '',
    venueKind: _enum(
      MeetupVenueKind.values,
      _camel(_strOrNull(j, 'venueKind')),
      MeetupVenueKind.otherPublic,
    ),
    venueName: _str(j, 'venueName'),
    venueAddress: _strOrNull(j, 'venueAddress'),
    city: _str(j, 'city'),
    region: _strOrNull(j, 'region'),
    country: _str(j, 'country'),
    startsAt: _time(j, 'startsAt'),
    endsAt: _timeOrNull(j, 'endsAt'),
    audience: _enum(
      MeetupAudience.values,
      _strOrNull(j, 'audience'),
      MeetupAudience.open,
    ),
    guardianRsvpForMinors: _strOrNull(j, 'minorsPolicy') == 'guardian_rsvp',
    capacity: j['capacity'] is num ? (j['capacity'] as num).toInt() : null,
    spotsLeft: j['spotsLeft'] is num ? (j['spotsLeft'] as num).toInt() : null,
    goingCount: _int(j, 'goingCount'),
    waitlistCount: _int(j, 'waitlistCount'),
    accessibilityNotes: _strOrNull(j, 'accessibilityNotes'),
    halalConfirmed: _bool(j, 'halalConfirmed'),
    status: _strOrNull(j, 'status') ?? 'published',
    recurrence: _enum(
      MeetupRecurrence.values,
      _strOrNull(j, 'recurrence'),
      MeetupRecurrence.none,
    ),
    cancelReason: _strOrNull(j, 'cancelReason'),
    organiser: MeetupOrganiser.fromJson(_map(j['organiser'])),
    mine: _bool(j, 'mine'),
    myRsvp: _strOrNull(j, 'myRsvp'),
  );

  final String id;
  final String title;
  final String description;
  final MeetupVenueKind venueKind;
  final String venueName;

  /// A public venue's street address, never a home.
  final String? venueAddress;
  final String city;
  final String? region;
  final String country;
  final DateTime startsAt;
  final DateTime? endsAt;
  final MeetupAudience audience;

  /// False means adults only.
  final bool guardianRsvpForMinors;
  final int? capacity;
  final int? spotsLeft;
  final int goingCount;
  final int waitlistCount;
  final String? accessibilityNotes;
  final bool halalConfirmed;

  /// published, pending_review, cancelled, hidden or ended.
  final String status;
  final MeetupRecurrence recurrence;
  final String? cancelReason;
  final MeetupOrganiser organiser;
  final bool mine;

  /// going, waitlist, cancelled or null.
  final String? myRsvp;

  bool get cancelled => status == 'cancelled';
  bool get pendingReview => status == 'pending_review';
  bool get isFull => spotsLeft != null && spotsLeft! <= 0;
  bool get iAmIn => myRsvp == 'going' || myRsvp == 'waitlist';
}

class MeetupList {
  const MeetupList({
    required this.meetups,
    this.hasMore = false,
    this.next,
  });

  factory MeetupList.fromJson(Map<String, dynamic> j) => MeetupList(
    meetups: _list(j['meetups']).map(Meetup.fromJson).toList(),
    hasMore: _bool(j, 'hasMore'),
    next: _strOrNull(j, 'next'),
  );

  final List<Meetup> meetups;
  final bool hasMore;
  final String? next;
}

class MeetupAttendee {
  const MeetupAttendee({
    required this.profileId,
    required this.displayName,
    required this.status,
  });

  factory MeetupAttendee.fromJson(Map<String, dynamic> j) => MeetupAttendee(
    profileId: _str(j, 'profileId'),
    displayName: _str(j, 'displayName'),
    status: _str(j, 'status'),
  );

  final String profileId;
  final String displayName;
  final String status;
}

/// Only the organiser gets this. A child's name is never listed.
class MeetupAttendees {
  const MeetupAttendees({required this.adults, required this.childrenGoing});

  factory MeetupAttendees.fromJson(Map<String, dynamic> j) => MeetupAttendees(
    adults: _list(j['adults']).map(MeetupAttendee.fromJson).toList(),
    childrenGoing: _int(j, 'childrenGoing'),
  );

  final List<MeetupAttendee> adults;
  final int childrenGoing;
}

class MeetupDetail {
  const MeetupDetail({required this.meetup, this.attendees});

  factory MeetupDetail.fromJson(Map<String, dynamic> j) => MeetupDetail(
    meetup: Meetup.fromJson(_map(j['meetup'])),
    attendees: j['attendees'] is Map<String, dynamic>
        ? MeetupAttendees.fromJson(_map(j['attendees']))
        : null,
  );

  final Meetup meetup;
  final MeetupAttendees? attendees;
}

/// What the organiser fills in. There is deliberately no free "address"
/// that could be a home: [venueName] is the public place, [venueAddress]
/// that place's street address.
class MeetupDraft {
  const MeetupDraft({
    required this.title,
    required this.venueKind,
    required this.venueName,
    required this.city,
    required this.country,
    required this.startsAt,
    required this.audience,
    this.description = '',
    this.venueAddress,
    this.endsAt,
    this.guardianRsvpForMinors = false,
    this.capacity,
    this.accessibilityNotes,
    this.halalConfirmed = false,
    this.recurrence = MeetupRecurrence.none,
    this.repeatTimes = 0,
  });

  final String title;
  final String description;
  final MeetupVenueKind venueKind;
  final String venueName;
  final String? venueAddress;
  final String city;

  /// Two-letter country code.
  final String country;
  final DateTime startsAt;
  final DateTime? endsAt;
  final MeetupAudience audience;
  final bool guardianRsvpForMinors;
  final int? capacity;
  final String? accessibilityNotes;

  /// Needed for a cafe: the organiser confirms the food is halal.
  final bool halalConfirmed;
  final MeetupRecurrence recurrence;

  /// How many more times it repeats after the first (0 to 11).
  final int repeatTimes;

  /// The later dates, keeping the same clock time (so a meet-up at 18:30
  /// stays at 18:30 across a clock change).
  List<DateTime> get occurrences {
    if (recurrence == MeetupRecurrence.none) return <DateTime>[];
    final int n = repeatTimes.clamp(0, 11);
    final DateTime s = startsAt;
    DateTime at(int days, int months) => s.isUtc
        ? DateTime.utc(
            s.year,
            s.month + months,
            s.day + days,
            s.hour,
            s.minute,
          )
        : DateTime(s.year, s.month + months, s.day + days, s.hour, s.minute);
    return <DateTime>[
      for (int i = 1; i <= n; i++)
        switch (recurrence) {
          MeetupRecurrence.weekly => at(7 * i, 0),
          MeetupRecurrence.biweekly => at(14 * i, 0),
          MeetupRecurrence.monthly => at(0, i),
          MeetupRecurrence.none => s,
        },
    ];
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'title': title,
    'description': description,
    'venueKind': _snake(venueKind.name),
    'venueName': venueName,
    if (venueAddress != null && venueAddress!.trim().isNotEmpty)
      'venueAddress': venueAddress,
    'city': city,
    'country': country,
    'startsAt': startsAt.toUtc().toIso8601String(),
    if (endsAt != null) 'endsAt': endsAt!.toUtc().toIso8601String(),
    'audience': audience.name,
    'minorsPolicy': guardianRsvpForMinors ? 'guardian_rsvp' : 'adults_only',
    if (capacity != null) 'capacity': capacity,
    if (accessibilityNotes != null && accessibilityNotes!.trim().isNotEmpty)
      'accessibilityNotes': accessibilityNotes,
    'halalConfirmed': halalConfirmed,
    if (recurrence != MeetupRecurrence.none) 'recurrence': recurrence.name,
    if (occurrences.isNotEmpty)
      'occurrences': <String>[
        for (final DateTime d in occurrences) d.toUtc().toIso8601String(),
      ],
    'acknowledgeOrganiserRules': true,
  };
}

/// `PUT /v1/meetups/:id/rsvp`.
class RsvpResult {
  const RsvpResult({required this.status, this.childStatus});

  factory RsvpResult.fromJson(Map<String, dynamic> j) {
    final Map<String, dynamic> r = _map(j['rsvp']);
    return RsvpResult(
      status: _str(r, 'status'),
      childStatus: _strOrNull(r, 'childStatus'),
    );
  }

  /// going or waitlist.
  final String status;
  final String? childStatus;
}

class MeetupReminder {
  const MeetupReminder({
    required this.meetupId,
    required this.title,
    required this.startsAt,
    required this.venueName,
    required this.city,
    required this.remindAt,
  });

  factory MeetupReminder.fromJson(Map<String, dynamic> j) => MeetupReminder(
    meetupId: _str(j, 'meetupId'),
    title: _str(j, 'title'),
    startsAt: _time(j, 'startsAt'),
    venueName: _str(j, 'venueName'),
    city: _str(j, 'city'),
    remindAt: (j['remindAt'] is List<dynamic>)
        ? (j['remindAt'] as List<dynamic>)
              .whereType<String>()
              .map(DateTime.parse)
              .toList()
        : <DateTime>[],
  );

  final String meetupId;
  final String title;
  final DateTime startsAt;
  final String venueName;
  final String city;
  final List<DateTime> remindAt;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.createdAt,
    this.payload = const <String, dynamic>{},
    this.readAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    id: _str(j, 'id'),
    kind: _str(j, 'kind'),
    payload: j['payload'] is Map<String, dynamic>
        ? j['payload'] as Map<String, dynamic>
        : const <String, dynamic>{},
    readAt: _timeOrNull(j, 'readAt'),
    createdAt: _time(j, 'createdAt'),
  );

  final String id;

  /// A short code (friend_request, reply, meetup_cancelled, ...). The app
  /// writes the words; the payload holds ids only.
  final String kind;
  final Map<String, dynamic> payload;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get unread => readAt == null;
}

class NotificationPage {
  const NotificationPage({
    required this.unreadCount,
    required this.notifications,
    this.serverTime,
  });

  factory NotificationPage.fromJson(Map<String, dynamic> j) =>
      NotificationPage(
        serverTime: _timeOrNull(j, 'serverTime'),
        unreadCount: _int(j, 'unreadCount'),
        notifications: _list(
          j['notifications'],
        ).map(AppNotification.fromJson).toList(),
      );

  final DateTime? serverTime;
  final int unreadCount;
  final List<AppNotification> notifications;
}

class ModerationNotice {
  const ModerationNotice({
    required this.id,
    required this.action,
    required this.reason,
    required this.createdAt,
    required this.appealable,
    this.appealStatus,
  });

  factory ModerationNotice.fromJson(Map<String, dynamic> j) =>
      ModerationNotice(
        id: _str(j, 'id'),
        action: _str(j, 'action'),
        reason: _str(j, 'reason'),
        createdAt: _time(j, 'createdAt'),
        appealable: _bool(j, 'appealable'),
        appealStatus: j['appeal'] is Map<String, dynamic>
            ? _strOrNull(_map(j['appeal']), 'status')
            : null,
      );

  final String id;
  final String action;

  /// The reason a moderator gave, in words a person can read.
  final String reason;
  final DateTime createdAt;
  final bool appealable;
  final String? appealStatus;
}

/// `GET /v1/me/moderation`: what moderators did about me.
class ModerationInfo {
  const ModerationInfo({
    required this.accountStatus,
    required this.strikePoints,
    required this.actions,
  });

  factory ModerationInfo.fromJson(Map<String, dynamic> j) => ModerationInfo(
    accountStatus: _strOrNull(j, 'accountStatus') ?? 'active',
    strikePoints: _int(j, 'strikePoints'),
    actions: _list(j['actions']).map(ModerationNotice.fromJson).toList(),
  );

  final String accountStatus;
  final int strikePoints;
  final List<ModerationNotice> actions;
}
