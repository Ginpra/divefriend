import 'package:divefriend/data/models/access_point.dart';

const String _spotDataSource = 'Data spot di aplikasi (lihat Sumber data di Detail Spot)';

/// Pintu masuk tiap spot, kuncinya id spot. Nama tempat dikirim ke Google Maps apa adanya,
/// bukan koordinat karangan, supaya Google yang menentukan titik jalannya.
/// Jadwal kapal dan pesawat sering berubah, jadi teksnya sengaja tidak menyebut jam atau harga.
const Map<String, AccessPoint> accessPointsBySpotId = {
  'bunaken': AccessPoint(
    name: 'Pelabuhan Manado, Sulawesi Utara',
    mapsQuery: 'Pelabuhan Manado, Sulawesi Utara',
    steps: 'Terbang ke Bandara Sam Ratulangi di Manado, lalu menuju pelabuhan Manado. '
        'Dari sana kapal motor menyeberang ke Bunaken sekitar 30 sampai 45 menit.',
    sources: [
      'whatsnewindonesia.com (Ultimate Guide to Bunaken Island)',
      'traveloka.com (Bunaken, halaman destinasi)',
    ],
  ),
  'wakatobi': AccessPoint(
    name: 'Bandara Matahora, Wangi-Wangi',
    mapsQuery: 'Bandara Matahora, Wakatobi',
    steps: 'Penerbangan ke Wakatobi mendarat di Bandara Matahora, Pulau Wangi-Wangi, biasanya lewat Makassar dan Kendari. '
        'Jadwal penerbangannya sering berubah, jadi cek dulu sebelum berangkat. '
        'Alternatifnya naik kapal dari Kendari atau Baubau ke Pelabuhan Wanci. '
        'Dari Wangi-Wangi, kapal antarpulau menghubungkan Kaledupa, Tomia, dan Binongko.',
    sources: [
      'indonesia.tripcanvas.co (Panduan wisata ke Wakatobi)',
      'indonesia.travel (7 hal tentang Wakatobi)',
      'Wikivoyage (Wakatobi)',
    ],
  ),
  'raja-ampat': AccessPoint(
    name: 'Bandara Domine Eduard Osok, Sorong',
    mapsQuery: 'Bandara Domine Eduard Osok, Sorong',
    steps: 'Terbang ke Sorong dari Jakarta, Makassar, Ambon, atau Manado. '
        'Dari bandara ke pelabuhan Sorong sekitar 15 menit, lalu kapal cepat ke Waisai di Pulau Waigeo sekitar 2 jam. '
        'Banyak penyelam memilih kapal liveaboard untuk menjelajah kawasannya.',
    sources: [
      'divernet.com (How to Get to Raja Ampat, oleh Meridian Adventure Dive)',
      'geckoroutes.com (Raja Ampat: how to get there)',
    ],
  ),
  'komodo': AccessPoint(
    name: 'Bandara Komodo, Labuan Bajo',
    mapsQuery: 'Bandara Komodo, Labuan Bajo',
    steps: 'Terbang ke Bandara Komodo di Labuan Bajo, Flores, biasanya lewat Bali. '
        'Bandara hanya beberapa menit dari pelabuhan, dan semua kapal menuju taman nasional berangkat dari pelabuhan itu.',
    sources: [
      'divetribekomodo.com (How to Get to Komodo Island)',
      'thesmartlocal.com (Guide to Komodo Island and Labuan Bajo)',
    ],
  ),
  'karimunjawa': AccessPoint(
    name: 'Pelabuhan Kartini, Jepara',
    mapsQuery: 'Pelabuhan Kartini, Jepara',
    steps: 'Naik kapal feri Siginjai atau kapal cepat Express Bahari dari Pelabuhan Kartini di Jepara. '
        'Ada juga penerbangan dari Semarang ke Bandara Dewadaru di Karimunjawa.',
    sources: ['indonesia.travel (Karimunjawa)'],
  ),
  'derawan': AccessPoint(
    name: 'Pelabuhan Tanjung Batu, Berau',
    mapsQuery: 'Pelabuhan Tanjung Batu, Berau',
    steps: 'Terbang ke Bandara Kalimarau di Berau, lanjut lewat darat sekitar 2 sampai 3 jam ke Tanjung Batu, '
        'lalu naik speedboat ke Pulau Derawan.',
    sources: [
      'telkomsel.com (Derawan Island: Underwater Paradise)',
      'goasia.cc (Derawan Islands)',
    ],
  ),
  'weh': AccessPoint(
    name: 'Pelabuhan Ulee Lheue, Banda Aceh',
    mapsQuery: 'Pelabuhan Ulee Lheue, Banda Aceh',
    steps: 'Dari Banda Aceh, kapal cepat menyeberang sekitar satu jam dari Pelabuhan Ulee Lheue ke Balohan di Pulau Weh.',
    sources: [_spotDataSource],
  ),
  'togean': AccessPoint(
    name: 'Ampana, Sulawesi Tengah',
    mapsQuery: 'Ampana, Tojo Una-Una',
    steps: 'Dari daratan Sulawesi, akses ke Kepulauan Togean lewat Ampana atau Gorontalo dengan kapal.',
    sources: [_spotDataSource],
  ),
  'lembeh': AccessPoint(
    name: 'Bitung, Sulawesi Utara',
    mapsQuery: 'Bitung, Sulawesi Utara',
    steps: 'Dari Manado naik bus ke Bitung, lalu menyeberang sekitar 15 menit dengan perahu ke Pulau Lembeh.',
    sources: [_spotDataSource],
  ),
  'gili': AccessPoint(
    name: 'Pelabuhan Padang Bai, Bali',
    mapsQuery: 'Pelabuhan Padang Bai, Karangasem',
    steps: 'Dari Bali, kapal cepat berangkat dari Padang Bai atau Sanur menuju Kepulauan Gili.',
    sources: [_spotDataSource],
  ),
  'nusa-penida': AccessPoint(
    name: 'Pelabuhan Sanur, Denpasar',
    mapsQuery: 'Pelabuhan Sanur, Denpasar',
    steps: 'Dari Bali, kapal berangkat dari Sanur atau Benoa. Perjalanan dengan kapal liveaboard sekitar dua jam.',
    sources: [_spotDataSource],
  ),
  'tulamben': AccessPoint(
    name: 'Pantai Tulamben (USAT Liberty), Bali',
    mapsQuery: '-8.27441,115.5949',
    steps: 'Tulamben ada di daratan Bali, jadi Google Maps bisa menghitung rute darat langsung sampai ke pantainya. '
        'Dari kota di pulau lain, kamu tetap perlu menyeberang atau terbang ke Bali dulu.',
    sources: [_spotDataSource],
  ),
  'cenderawasih': AccessPoint(
    name: 'Nabire, Papua',
    mapsQuery: 'Nabire, Papua',
    steps: 'Pengunjung bisa terbang ke Biak, dan dari Nabire perjalanan ke taman sekitar tiga jam dengan speedboat. '
        'Kebanyakan wisatawan asing datang lewat kapal liveaboard.',
    sources: [_spotDataSource],
  ),
  'banda': AccessPoint(
    name: 'Bandara Pattimura, Ambon',
    mapsQuery: 'Bandara Pattimura, Ambon',
    steps: 'Dari Ambon, kapal cepat ke Banda Neira berangkat dari Pelabuhan Tulehu dan memakan waktu sekitar enam jam. '
        'Ada juga penerbangan kecil Susi Air dari Ambon, serta kapal Pelni yang jadwalnya jarang. '
        'Semua jadwalnya sering berubah, jadi pastikan dulu sebelum berangkat.',
    sources: [
      'Sygic Travel (Banda Islands, dari Wikivoyage)',
      'tamanbacaanpelangi.com (Exploring Eastern Indonesia: Banda Naira)',
    ],
  ),
  'menjangan': AccessPoint(
    name: 'Pelabuhan Labuan Lalang, Buleleng',
    mapsQuery: 'Labuhan Lalang, Buleleng',
    steps: 'Dari Bandara Ngurah Rai sekitar 4 jam lewat darat ke Pelabuhan Labuan Lalang, '
        'lalu naik perahu ke Pulau Menjangan sekitar 20 sampai 40 menit.',
    sources: [
      'balitouristic.com (Menjangan Island)',
      'indopacificimages.com (Diving Menjangan Island)',
    ],
  ),
};
