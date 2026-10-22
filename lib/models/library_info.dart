import 'package:flutter/material.dart';

/// A library service displayed on the landing page Services section.
/// All fields are persisted in the `library_services` SQLite table and
/// editable by administrators via the Library Info editor screen.
class LibraryService {
  final int? id;
  final String title;
  final String description;
  final String iconName;
  final int displayOrder;
  final bool isActive;

  LibraryService({
    this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.displayOrder,
    this.isActive = true,
  });

  /// Material icon name resolved via [Icons] mapping.
  IconData get icon => _iconMap[iconName] ?? Icons.menu_book_rounded;

  factory LibraryService.fromMap(Map<String, dynamic> m) => LibraryService(
        id: m['id'] as int?,
        title: m['title'] as String,
        description: m['description'] as String,
        iconName: m['icon_name'] as String? ?? 'menu_book',
        displayOrder: m['display_order'] as int? ?? 0,
        isActive: (m['is_active'] as int?) == 1,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'description': description,
        'icon_name': iconName,
        'display_order': displayOrder,
        'is_active': isActive ? 1 : 0,
      };

  LibraryService copyWith({
    int? id,
    String? title,
    String? description,
    String? iconName,
    int? displayOrder,
    bool? isActive,
  }) =>
      LibraryService(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        iconName: iconName ?? this.iconName,
        displayOrder: displayOrder ?? this.displayOrder,
        isActive: isActive ?? this.isActive,
      );
}

/// A step in the "How It Works" workflow shown on the landing page.
/// Persisted in the `library_steps` SQLite table.
class LibraryStep {
  final int? id;
  final int stepNumber;
  final String title;
  final String description;
  final String iconName;
  final int displayOrder;
  final bool isActive;

  LibraryStep({
    this.id,
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.iconName,
    required this.displayOrder,
    this.isActive = true,
  });

  IconData get icon => _iconMap[iconName] ?? Icons.search_rounded;

  factory LibraryStep.fromMap(Map<String, dynamic> m) => LibraryStep(
        id: m['id'] as int?,
        stepNumber: m['step_number'] as int? ?? 1,
        title: m['title'] as String,
        description: m['description'] as String,
        iconName: m['icon_name'] as String? ?? 'search',
        displayOrder: m['display_order'] as int? ?? 0,
        isActive: (m['is_active'] as int?) == 1,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'step_number': stepNumber,
        'title': title,
        'description': description,
        'icon_name': iconName,
        'display_order': displayOrder,
        'is_active': isActive ? 1 : 0,
      };

  LibraryStep copyWith({
    int? id,
    int? stepNumber,
    String? title,
    String? description,
    String? iconName,
    int? displayOrder,
    bool? isActive,
  }) =>
      LibraryStep(
        id: id ?? this.id,
        stepNumber: stepNumber ?? this.stepNumber,
        title: title ?? this.title,
        description: description ?? this.description,
        iconName: iconName ?? this.iconName,
        displayOrder: displayOrder ?? this.displayOrder,
        isActive: isActive ?? this.isActive,
      );
}

/// A message submitted via the Contact section form.
class ContactMessage {
  final int? id;
  final String name;
  final String email;
  final String subject;
  final String message;
  final DateTime submittedAt;
  final bool isHandled;

  ContactMessage({
    this.id,
    required this.name,
    required this.email,
    required this.subject,
    required this.message,
    required this.submittedAt,
    this.isHandled = false,
  });

  factory ContactMessage.fromMap(Map<String, dynamic> m) => ContactMessage(
        id: m['id'] as int?,
        name: m['name'] as String,
        email: m['email'] as String,
        subject: m['subject'] as String,
        message: m['message'] as String,
        submittedAt:
            DateTime.fromMillisecondsSinceEpoch(m['submitted_at'] as int),
        isHandled: (m['is_handled'] as int?) == 1,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'email': email,
        'subject': subject,
        'message': message,
        'submitted_at': submittedAt.millisecondsSinceEpoch,
        'is_handled': isHandled ? 1 : 0,
      };
}

/// Aggregated contact info for the landing page, all from the settings table.
class LibraryContactInfo {
  final String libraryName;
  final String tagline;
  final String mission;
  final String vision;
  final String history;
  final String email;
  final String phone;
  final String address;
  final String hours;
  final String? facebook;
  final String? twitter;
  final String? instagram;

  const LibraryContactInfo({
    required this.libraryName,
    required this.tagline,
    required this.mission,
    required this.vision,
    required this.history,
    required this.email,
    required this.phone,
    required this.address,
    required this.hours,
    this.facebook,
    this.twitter,
    this.instagram,
  });
}

/// Mapping of icon_name strings (stored in DB) to Material [Icons].
/// Adding a new icon means adding one entry here.
const Map<String, IconData> _iconMap = {
  'menu_book': Icons.menu_book_rounded,
  'self_improvement': Icons.self_improvement_rounded,
  'psychology': Icons.psychology_rounded,
  'local_shipping': Icons.local_shipping_rounded,
  'devices': Icons.devices_rounded,
  'school': Icons.school_rounded,
  'print': Icons.print_rounded,
  'wifi': Icons.wifi_rounded,
  'search': Icons.search_rounded,
  'local_library': Icons.local_library_rounded,
  'assignment_return': Icons.assignment_return_rounded,
  'bookmark': Icons.bookmark_rounded,
  'people': Icons.people_outline_rounded,
  'inventory': Icons.inventory_2_outlined,
  'category': Icons.category_outlined,
  'settings': Icons.settings_outlined,
  'help': Icons.help_outline_rounded,
  'email': Icons.mail_outline_rounded,
  'phone': Icons.phone_outlined,
  'location': Icons.location_on_outlined,
  'schedule': Icons.schedule_rounded,
  'public': Icons.public_rounded,
};
