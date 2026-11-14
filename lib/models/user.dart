/// Represents non-sensitive authenticated user information.
class User {
  final int id;
  final String fullName;
  final String email;
  final String role;
  final String subscriptionType;
  final String? profilePicture;
  final int? currentStageId;

  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.subscriptionType,
    this.profilePicture,
    this.currentStageId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _asInt(json['Id'] ?? json['id']),
      fullName: _asString(json['FullName'] ?? json['fullName']),
      email: _asString(json['Email'] ?? json['email']),
      role: _asString(json['Role'] ?? json['role'], fallback: 'Student'),
      subscriptionType: _asString(
        json['SubscriptionType'] ?? json['subscriptionType'],
        fallback: 'Free',
      ),
      profilePicture: _asNullableString(
        json['ProfilePicture'] ?? json['profilePicture'],
      ),
      currentStageId: _asNullableInt(
        json['CurrentStageId'] ?? json['currentStageId'],
      ),
    );
  }

  Map<String, dynamic> toCacheJson() {
    return {
      'Id': id,
      'FullName': fullName,
      'Email': email,
      'Role': role,
      'SubscriptionType': subscriptionType,
      if (profilePicture != null) 'ProfilePicture': profilePicture,
      if (currentStageId != null) 'CurrentStageId': currentStageId,
    };
  }
  User copyWith({int? currentStageId, String? subscriptionType}) {
    return User(
      id: id,
      fullName: fullName,
      email: email,
      role: role,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      profilePicture: profilePicture,
      currentStageId: currentStageId ?? this.currentStageId,
    );
  }
}

/// Represents an authentication response containing a token and user data.
class AuthResult {
  final User user;
  final String token;

  const AuthResult({required this.user, required this.token});

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    final nestedUser = json['User'] ?? json['user'];
    final userMap =
        nestedUser is Map ? Map<String, dynamic>.from(nestedUser) : json;
    final token = _asString(json['Token'] ?? json['token']);
    if (token.isEmpty) {
      throw const FormatException('Authentication token is missing.');
    }
    return AuthResult(user: User.fromJson(userMap), token: token);
  }
}

/// Represents an extended profile returned by the profile endpoint.
class UserProfile extends User {
  final int solvedProblemsCount;
  final int totalPoints;
  final DateTime? memberSince;

  const UserProfile({
    required super.id,
    required super.fullName,
    required super.email,
    required super.role,
    required super.subscriptionType,
    super.profilePicture,
    super.currentStageId,
    required this.solvedProblemsCount,
    required this.totalPoints,
    required this.memberSince,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: _asInt(json['Id'] ?? json['id']),
      fullName: _asString(json['FullName'] ?? json['fullName']),
      email: _asString(json['Email'] ?? json['email']),
      role: _asString(json['Role'] ?? json['role'], fallback: 'Student'),
      subscriptionType: _asString(
        json['SubscriptionType'] ?? json['subscriptionType'],
        fallback: 'Free',
      ),
      profilePicture: _asNullableString(
        json['ProfilePicture'] ?? json['profilePicture'],
      ),
      currentStageId: _asNullableInt(
        json['CurrentStageId'] ?? json['currentStageId'],
      ),
      solvedProblemsCount: _asInt(
        json['SolvedProblemsCount'] ?? json['solvedProblemsCount'],
      ),
      totalPoints: _asInt(json['TotalPoints'] ?? json['totalPoints']),
      memberSince: _asDateTime(json['MemberSince'] ?? json['memberSince']),
    );
  }
}

int? _asNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

int _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _asString(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String? _asNullableString(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

DateTime? _asDateTime(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  return DateTime.tryParse(value?.toString() ?? '');
}
