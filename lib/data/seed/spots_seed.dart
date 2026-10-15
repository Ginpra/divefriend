import 'package:divefriend/data/models/spot.dart';

/// Naikkan angka ini setiap kali isi [spotsSeed] diubah, supaya database
/// di HP memuat ulang data terbaru saat aplikasi dibuka.
const int spotsSeedVersion = 1;

const String _levelNote =
    'Estimasi sementara tim, belum ada sumber penilaian level. Perlu ditinjau.';
const String _timeZoneNote =
    'Zona waktu: ditentukan dari provinsi (aturan zona waktu Indonesia).';

/// Data spot hasil kurasi manual. Aturan: setiap nilai harus punya sumber;
/// yang tidak ditemukan dibiarkan kosong (tampil "tidak tersedia").
/// Tahap 3B menambah spot dan foto berlisensi terbuka.
const List<Spot> spotsSeed = [
  Spot(
    id: 'bunaken',
    name: 'Taman Nasional Bunaken',
    region: 'Sulawesi Utara',
    level: SpotLevel.pemula,
    levelBasis: _levelNote,
    types: [SpotType.scuba, SpotType.snorkeling],
    summary:
        'Taman laut seluas sekitar 890 km2 di utara Sulawesi. Pantainya langsung '
        'turun ke lereng benua tanpa paparan, sehingga membentuk dinding karang '
        'yang menarik bagi penyelam. Suhu air 27-29 derajat Celsius.',
    biota: [
      'Kima raksasa (7 dari 8 spesies dunia)',
      'Ikan gobi',
      'Penyu',
      'Sekitar 390 spesies karang',
    ],
    latitude: 1.667,
    longitude: 124.650,
    timeZoneLabel: 'WITA',
    sources: [
      'Wikipedia: Bunaken National Park (koordinat) - https://en.wikipedia.org/wiki/Bunaken_National_Park',
      'Wikipedia: Bunaken (suhu air, kima raksasa, ikan gobi) - https://en.wikipedia.org/wiki/Bunaken',
      'UNESCO Tentative List (dasar laut curam) - https://whc.unesco.org/en/tentativelists/2002',
      'Two Fish Divers (390 spesies karang, menyelam dan snorkeling) - https://oldsite.twofishdivers.com/?p=21104',
      'National-Parks.org (penyu) - https://national-parks.org/indonesia/bunaken-national-park/',
      _timeZoneNote,
    ],
  ),
  Spot(
    id: 'wakatobi',
    name: 'Wakatobi',
    region: 'Sulawesi Tenggara',
    level: SpotLevel.menengah,
    levelBasis: _levelNote,
    types: [SpotType.scuba],
    summary:
        'Gugusan sekitar 150 pulau di Sulawesi Tenggara, bagian dari Segitiga '
        'Terumbu Karang. Taman nasionalnya seluas sekitar 1,39 juta hektare. '
        'Lanskap bawah lautnya mencakup atol, dinding, gunung laut, dan karang penghalang.',
    latitude: -5.53583,
    longitude: 123.75806,
    timeZoneLabel: 'WITA',
    sources: [
      'Wikipedia: Wakatobi Regency (koordinat, luas, jumlah pulau) - https://en.wikipedia.org/wiki/Wakatobi_Regency',
      'Underwater Asia (jenis lanskap selam) - https://dev.underwaterasia.info/countries/indonesia',
      _timeZoneNote,
    ],
  ),
  Spot(
    id: 'raja-ampat',
    name: 'Raja Ampat',
    region: 'Papua Barat Daya',
    level: SpotLevel.lanjutan,
    levelBasis: _levelNote,
    types: [SpotType.scuba],
    summary:
        'Kepulauan terpencil dengan 612 pulau di ujung barat laut Papua. Dikenal '
        'sebagai salah satu tujuan selam terbaik, terutama lewat perjalanan liveaboard. '
        'Keragaman karangnya menjadikannya prioritas konservasi dunia.',
    latitude: -0.2333115,
    longitude: 130.5078908,
    timeZoneLabel: 'WIT',
    sources: [
      'Wikipedia: Raja Ampat Islands (koordinat, jumlah pulau) - https://www.wikipedia.org/wiki/Raja_Ampat',
      'Underwater Asia (liveaboard, kualitas selam) - https://dev.underwaterasia.info/countries/indonesia',
      _timeZoneNote,
    ],
  ),
  Spot(
    id: 'komodo',
    name: 'Taman Nasional Komodo',
    region: 'Nusa Tenggara Timur',
    level: SpotLevel.lanjutan,
    levelBasis:
        'Perairannya disebut disapu arus dan kaya satwa pelagis (Underwater Asia). '
        'Estimasi tim, perlu ditinjau.',
    types: [SpotType.scuba, SpotType.snorkeling],
    summary:
        'Taman nasional di antara Pulau Sumbawa dan Flores, ditetapkan UNESCO '
        'pada 1991 dengan luas 219.322 hektare. Selain habitat biawak komodo, '
        'perairannya memiliki terumbu karang yang kaya.',
    latitude: -8.543,
    longitude: 119.489,
    timeZoneLabel: 'WITA',
    sources: [
      'UNESCO World Heritage: Komodo National Park (koordinat, luas, tahun) - https://whc.unesco.org/document/217032',
      'Underwater Asia (arus, satwa pelagis) - https://dev.underwaterasia.info/countries/indonesia',
      'Luxury Hunt (menyelam dan snorkeling) - https://www.luxuryhunt.com/sleep/indonesia/alila-purnama/',
      _timeZoneNote,
    ],
  ),
];
