/// Reusable form validators for IULMS.
class Validators {
  const Validators._();

  static String? required(String? value, {String label = 'This field'}) {
    final v = value?.trim();
    if (v == null || v.isEmpty) return '$label is required';
    return null;
  }

  static String? username(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Username is required';
    if (v.length < 3) return 'At least 3 characters';
    if (!RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(v)) {
      return 'Only letters, digits, dot, underscore';
    }
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(v)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'At least 6 characters';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    final v = value ?? '';
    if (v.isEmpty) return 'Confirm your password';
    if (v != original) return 'Passwords do not match';
    return null;
  }

  static String? isbn(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'ISBN is required';
    final cleaned = v.replaceAll(RegExp(r'[^0-9Xx]'), '');
    if (cleaned.length != 10 && cleaned.length != 13) {
      return 'ISBN must be 10 or 13 characters';
    }
    return null;
  }

  static String? positiveInt(String? value, {String label = 'Quantity'}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '$label is required';
    final n = int.tryParse(v);
    if (n == null) return 'Enter a valid number';
    if (n < 0) return '$label cannot be negative';
    return null;
  }

  static String? year(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Year is required';
    final n = int.tryParse(v);
    if (n == null) return 'Enter a valid year';
    final now = DateTime.now().year;
    if (n < 1500 || n > now + 1) return 'Enter a year between 1500 and ${now + 1}';
    return null;
  }

  static String? studentId(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Student ID is required';
    if (v.length < 4) return 'Student ID seems too short';
    return null;
  }
}
