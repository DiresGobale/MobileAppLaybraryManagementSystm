import 'dart:convert';

class Category {
  final int? id;
  final String name;
  final String? description;

  Category({this.id, required this.name, this.description});

  factory Category.fromMap(Map<String, dynamic> m) => Category(
        id: m['id'] as int?,
        name: m['name'] as String,
        description: m['description'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'description': description,
      };

  Category copyWith({int? id, String? name, String? description}) => Category(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
      );
}
