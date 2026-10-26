import '../../academy/application/family_service.dart';

/// What the family check says about opening an online table.
class OnlineVerdict {
  const OnlineVerdict._(this.blocked, this.needsParent, this.message);

  /// Nothing in the way: no child profiles, or the learner is a child whose
  /// guardian switched online tables on.
  static const OnlineVerdict allowed = OnlineVerdict._(false, false, '');

  /// The device has child profiles and nobody is chosen as the learner (a
  /// child can pick "Nobody"), so an adult answers the parent check first.
  static const OnlineVerdict parentCheck = OnlineVerdict._(false, true, '');

  /// The learner is a child whose guardian has NOT switched tables on.
  factory OnlineVerdict.childOff(String childName) => OnlineVerdict._(
        true,
        false,
        'Online tables are off for $childName. A parent or guardian can turn '
        'them on in the Family Wing, on $childName’s card, under '
        '“Online game tables”. Until then you can still play on '
        'this device.',
      );

  final bool blocked;
  final bool needsParent;
  final String message;
}

/// The rule in front of every online table (Ludo and Shatranj).
///
///  * A child profile can create or join a table only when a guardian has
///    switched "Online game tables" on for that child in the Family Wing.
///    It is OFF for every new child.
///  * With child profiles on the device but nobody chosen as the learner, the
///    parent check comes first (otherwise "Nobody" would be a way round it).
///  * A device with no child profiles is an adult's: no extra step.
class OnlineAccess {
  OnlineAccess({FamilyService? family}) : _family = family ?? FamilyService();

  final FamilyService _family;

  Future<OnlineVerdict> check() async {
    try {
      final List<Map<String, dynamic>> kids = await _family.children();
      if (kids.isEmpty) return OnlineVerdict.allowed;
      final String? id = await _family.activeChildId();
      if (id == null) return OnlineVerdict.parentCheck;
      Map<String, dynamic>? child;
      for (final Map<String, dynamic> c in kids) {
        if (c['id'] == id) child = c;
      }
      if (child == null) return OnlineVerdict.parentCheck;
      if (await _family.onlineGamesAllowed(id)) return OnlineVerdict.allowed;
      final Object? n = child['name'];
      return OnlineVerdict.childOff(n is String && n.isNotEmpty ? n : 'this child');
    } catch (_) {
      // If the family store cannot be read, fail closed: ask a parent.
      return OnlineVerdict.parentCheck;
    }
  }
}
