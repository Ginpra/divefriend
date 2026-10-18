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

/// Validator form Logbook: kedalaman maksimum (meter), lama di dasar (menit), dan catatan bebas.
const int maxLogDepthMeters = 150;
const int maxLogBottomTimeMinutes = 300;
const int maxLogNotesLength = 500;

String? validateDepthMeters(String? value) {
  final depth = int.tryParse((value ?? '').trim());
  if (depth == null || depth < 1 || depth > maxLogDepthMeters) {
    return 'Isi angka bulat 1 sampai $maxLogDepthMeters';
  }
  return null;
}

String? validateBottomTimeMinutes(String? value) {
  final minutes = int.tryParse((value ?? '').trim());
  if (minutes == null || minutes < 1 || minutes > maxLogBottomTimeMinutes) {
    return 'Isi angka bulat 1 sampai $maxLogBottomTimeMinutes';
  }
  return null;
}

String? validateLogNotes(String? value) {
  if ((value ?? '').trim().length > maxLogNotesLength) {
    return 'Maksimal $maxLogNotesLength karakter';
  }
  return null;
}
