/// The user's persisted profile record.
///
/// Today it carries identity only; journey progress, bookmarks, notes, and
/// settings attach to this record in later work packages. Storage is local
/// (SharedPreferences) until Firestore lands with O-4 — the repository seam
/// keeps that swap invisible to the UI.
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.createdAt,
  });

  final String uid;
  final String displayName;
  final String email;
  final DateTime createdAt;

  UserProfile copyWith({String? displayName}) {
    return UserProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'uid': uid,
    'displayName': displayName,
    'email': email,
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String,
      displayName: json['displayName'] as String,
      email: json['email'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
