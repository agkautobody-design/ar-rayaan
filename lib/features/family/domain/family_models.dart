/// Family domain models: multi-parent + live teacher support.
///
/// A [Family] is keyed by a generated familyId (not a parent UID),
/// so both parents and invited teachers can access it.

class FamilyMember {
  const FamilyMember({
    required this.uid,
    required this.role,
    required this.email,
    this.name,
    this.invitedBy,
    this.invitedAt,
  });

  final String uid;
  final String role; // 'parent', 'child', 'teacher'
  final String email;
  final String? name;
  final String? invitedBy;
  final DateTime? invitedAt;

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'role': role,
    'email': email,
    if (name != null) 'name': name,
    if (invitedBy != null) 'invitedBy': invitedBy,
    if (invitedAt != null) 'invitedAt': invitedAt!.toIso8601String(),
  };

  factory FamilyMember.fromJson(Map<String, dynamic> j) => FamilyMember(
    uid: j['uid'] as String,
    role: j['role'] as String,
    email: j['email'] as String,
    name: j['name'] as String?,
    invitedBy: j['invitedBy'] as String?,
    invitedAt: j['invitedAt'] != null
        ? DateTime.parse(j['invitedAt'] as String)
        : null,
  );
}

class Child {
  const Child({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    this.avatar,
    this.grade,
    this.notes,
  });

  final String id;
  final String name;
  final String email;
  final DateTime createdAt;
  final String? avatar;
  final String? grade;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'createdAt': createdAt.toIso8601String(),
    if (avatar != null) 'avatar': avatar,
    if (grade != null) 'grade': grade,
    if (notes != null) 'notes': notes,
  };

  factory Child.fromJson(Map<String, dynamic> j) => Child(
    id: j['id'] as String,
    name: j['name'] as String,
    email: j['email'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
    avatar: j['avatar'] as String?,
    grade: j['grade'] as String?,
    notes: j['notes'] as String?,
  );

  Child copyWith({String? name, String? avatar, String? grade, String? notes}) =>
      Child(
        id: id,
        name: name ?? this.name,
        email: email,
        createdAt: createdAt,
        avatar: avatar ?? this.avatar,
        grade: grade ?? this.grade,
        notes: notes ?? this.notes,
      );
}

class Family {
  const Family({
    required this.familyId,
    required this.members,
    required this.children,
    required this.createdAt,
    this.name,
  });

  final String familyId;
  final String? name;
  final List<FamilyMember> members;
  final List<Child> children;
  final DateTime createdAt;

  List<FamilyMember> get parents =>
      members.where((m) => m.role == 'parent').toList();

  List<FamilyMember> get teachers =>
      members.where((m) => m.role == 'teacher').toList();

  bool hasMember(String uid) => members.any((m) => m.uid == uid);

  Map<String, dynamic> toJson() => {
    'familyId': familyId,
    if (name != null) 'name': name,
    'members': members.map((m) => m.toJson()).toList(),
    'children': children.map((c) => c.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory Family.fromJson(Map<String, dynamic> j) => Family(
    familyId: j['familyId'] as String,
    name: j['name'] as String?,
    members: (j['members'] as List<dynamic>)
        .map((e) => FamilyMember.fromJson(e as Map<String, dynamic>))
        .toList(),
    children: (j['children'] as List<dynamic>)
        .map((e) => Child.fromJson(e as Map<String, dynamic>))
        .toList(),
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}
