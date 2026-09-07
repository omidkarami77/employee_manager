import 'package:pocketbase/pocketbase.dart';

import '../config/pocketbase_config.dart';

enum UserRole { admin, user }

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });
  final String id, name, email;
  final UserRole role;
  bool get isAdmin => role == UserRole.admin;
  String get roleLabel => isAdmin ? 'مدیر سیستم' : 'کاربر';
  String get displayName => name.trim().isEmpty ? email : name;

  static AppUser? fromRecord(RecordModel? record) {
    if (record == null ||
        record.id.isEmpty ||
        record.collectionName != PocketBaseConfig.authCollection) {
      return null;
    }
    final role = switch (record.getStringValue('role').trim().toLowerCase()) {
      'admin' => UserRole.admin,
      'user' => UserRole.user,
      _ => null,
    };
    if (role == null) return null;
    return AppUser(
      id: record.id,
      name: record.getStringValue('name'),
      email: record.getStringValue('email'),
      role: role,
    );
  }
}
