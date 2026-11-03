/// Family domain models: parent-child linking for academy monitoring.
///
/// A [Family] lives at /families/{parentUid} and holds [Child] records.
/// Each child gets their own Firebase Auth account (email + password)
/// so their progress, bookmarks, and academy data are fully separate.

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
    required this.parentUid,
    required this.parentEmail,
    required this.children,
    required this.createdAt,
  });

  final String parentUid;
  final String parentEmail;
  final List<Child> children;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'parentUid': parentUid,
    'parentEmail': parentEmail,
    'children': children.map((c) => c.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory Family.fromJson(Map<String, dynamic> j) => Family(
    parentUid: j['parentUid'] as String,
    parentEmail: j['parentEmail'] as String,
    children: (j['children'] as List<dynamic>)
        .map((e) => Child.fromJson(e as Map<String, dynamic>))
        .toList(),
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}
