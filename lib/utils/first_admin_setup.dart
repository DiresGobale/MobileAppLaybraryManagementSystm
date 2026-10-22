// ignore_for_file: avoid_print
//
// Run from the project root with:
//
//   dart run lib/utils/first_admin_setup.dart
//
// Prompts for an admin username, full name, email, and password, then inserts
// the first administrator account into the local SQLite database. Password is
// hashed with a per-user salt before storage.
//
// NOTE: This script must run with Flutter/dart support for the sqflite plugin.
// On Flutter desktop or pure Dart, use sqflite_common_ffi for the database.

import 'dart:io';

import 'package:iulms/database/database_helper.dart';
import 'package:iulms/models/user.dart';
import 'package:iulms/repositories/user_repository.dart';
import 'package:iulms/utils/hash_utils.dart';

Future<void> main(List<String> args) async {
  // Ensure FFI sqflite is initialized for non-mobile platforms.
  // Importing this here would require sqflite_common_ffi in dependencies,
  // which is already in dev_dependencies. In production Flutter it's
  // unnecessary; this script targets Dart CLI use only.
  print('=== Injibara University Library · First Administrator Setup ===\n');

  // If already initialized, abort.
  if (await DatabaseHelper.instance.hasAnyUser) {
    print('An administrator account already exists on this device. Aborting.');
    exit(1);
  }

  stdout.write('Full name: ');
  final fullName = stdin.readLineSync()!.trim();
  stdout.write('Username (lowercase, no spaces): ');
  final username = stdin.readLineSync()!.trim();
  stdout.write('Email: ');
  final email = stdin.readLineSync()!.trim();
  stdout.write('Password (min 6 chars): ');
  final password = stdin.readLineSync()!;

  if (fullName.isEmpty || username.isEmpty || email.isEmpty || password.length < 6) {
    print('Invalid input. Ensure full name, username, email are non-empty and '
        'password is at least 6 characters.');
    exit(2);
  }

  final repo = UserRepository(DatabaseHelper.instance);
  if (await repo.findByUsername(username) != null) {
    print('That username is already taken.');
    exit(3);
  }
  if (await repo.findByEmail(email) != null) {
    print('That email is already registered.');
    exit(4);
  }

  final salt = HashUtils.generateSalt();
  final hash = HashUtils.hashPassword(password, salt);
  final now = DateTime.now();
  final user = User(
    fullName: fullName,
    username: username,
    email: email,
    passwordHash: hash,
    passwordSalt: salt,
    role: Role.admin,
    createdAt: now,
    isActive: true,
  );
  final id = await repo.create(user);
  print('\nAdministrator created successfully (id=$id). You can now launch '
      'the app and sign in.');
  exit(0);
}
