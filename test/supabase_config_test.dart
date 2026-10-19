import 'package:flutter_test/flutter_test.dart';

import 'package:divefriend/data/remote/supabase_config.dart';

void main() {
  test('isConfigured false untuk nilai template atau kosong', () {
    expect(const SupabaseConfig(url: 'ISI_DI_SECRETS_DART', apiKey: 'ISI_DI_SECRETS_DART').isConfigured, isFalse);
    expect(const SupabaseConfig(url: 'https://abc.supabase.co', apiKey: 'ISI_DI_SECRETS_DART').isConfigured, isFalse);
    expect(const SupabaseConfig(url: 'https://abc.supabase.co', apiKey: '').isConfigured, isFalse);
    expect(const SupabaseConfig(url: 'http://abc.supabase.co', apiKey: 'sb_publishable_x').isConfigured, isFalse);
  });

  test('isConfigured true untuk URL https dan kunci terisi', () {
    expect(const SupabaseConfig(url: 'https://abc.supabase.co', apiKey: 'sb_publishable_x').isConfigured, isTrue);
  });

  test('restBase membuang garis miring di akhir', () {
    expect(const SupabaseConfig(url: 'https://abc.supabase.co', apiKey: 'k').restBase, 'https://abc.supabase.co/rest/v1');
    expect(const SupabaseConfig(url: 'https://abc.supabase.co/', apiKey: 'k').restBase, 'https://abc.supabase.co/rest/v1');
  });
}
