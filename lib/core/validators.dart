/// Validator form yang dipakai bersama oleh beberapa layar (Login, Register, Saran & Kesan).
String? validateRequired(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Wajib diisi';
  }
  return null;
}

const int minPasswordLength = 8;

String? validateNewPassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Wajib diisi';
  }
  if (value.length < minPasswordLength) {
    return 'Minimal $minPasswordLength karakter';
  }
  return null;
}
