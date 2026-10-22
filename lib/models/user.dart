import 'dart:convert';

class User {
  final int? id;
  final String fullName;
  final String username;
  final String email;
  final String passwordHash;
  final String passwordSalt;
  final String role;
  final String? studentId;
  final String? department;
  final DateTime createdAt;
  final bool isActive;

  User({
    this.id,
    required this.fullName,
    required this.username,
    required this.email,
    required this.passwordHash,
    required this.passwordSalt,
    required this.role,
    this.studentId,
    this.department,
    required this.createdAt,
    this.isActive = true,
  });

  bool get isAdmin => role == 'admin';
  bool get isLibrarian => role == 'librarian';
  bool get isStudent => role == 'student';
  bool get canManageBooks => isAdmin || isLibrarian;
  bool get canManageUsers => isAdmin;
  bool get canIssueBooks => isAdmin || isLibrarian;

  factory User.fromMap(Map<String, dynamic> m) => User(
        id: m['id'] as int?,
        fullName: m['full_name'] as String,
        username: m['username'] as String,
        email: m['email'] as String,
        passwordHash: m['password_hash'] as String,
        passwordSalt: m['password_salt'] as String,
        role: m['role'] as String,
        studentId: m['student_id'] as String?,
        department: m['department'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        isActive: (m['is_active'] as int) == 1,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'full_name': fullName,
        'username': username,
        'email': email,
        'password_hash': passwordHash,
        'password_salt': passwordSalt,
        'role': role,
        'student_id': studentId,
        'department': department,
        'created_at': createdAt.millisecondsSinceEpoch,
        'is_active': isActive ? 1 : 0,
      };

  User copyWith({
    int? id,
    String? fullName,
    String? username,
    String? email,
    String? passwordHash,
    String? passwordSalt,
    String? role,
    String? studentId,
    String? department,
    DateTime? createdAt,
    bool? isActive,
  }) =>
      User(
        id: id ?? this.id,
        fullName: fullName ?? this.fullName,
        username: username ?? this.username,
        email: email ?? this.email,
        passwordHash: passwordHash ?? this.passwordHash,
        passwordSalt: passwordSalt ?? this.passwordSalt,
        role: role ?? this.role,
        studentId: studentId ?? this.studentId,
        department: department ?? this.department,
        createdAt: createdAt ?? this.createdAt,
        isActive: isActive ?? this.isActive,
      );

  @override
  String toString() => 'User($id, $username, $role, active=$isActive)';
}

class Role {
  static const String admin = 'admin';
  static const String librarian = 'librarian';
  static const String student = 'student';

  static String labelOf(String role) {
    switch (role) {
      case admin:
        return 'Administrator';
      case librarian:
        return 'Librarian';
      case student:
        return 'Student';
      default:
        return role;
    }
  }
}
