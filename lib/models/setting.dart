class Setting {
  final int? id;
  final String key;
  final String value;

  Setting({this.id, required this.key, required this.value});

  factory Setting.fromMap(Map<String, dynamic> m) => Setting(
        id: m['id'] as int?,
        key: m['setting_key'] as String,
        value: m['setting_value'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'setting_key': key,
        'setting_value': value,
      };
}
