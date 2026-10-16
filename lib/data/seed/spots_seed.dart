import 'package:divefriend/data/models/spot.dart';

/// Naikkan angka ini setiap kali isi [spotsSeed] diubah, supaya database
/// di HP memuat ulang data terbaru saat aplikasi dibuka.
const int spotsSeedVersion = 2;

const String _levelNote =
    'Estimasi sementara tim, belum ada sumber penilaian level. Perlu ditinjau.';
const String _timeZoneNote =
    'Zona waktu: ditentukan dari provinsi (aturan zona waktu Indonesia).';

/// Data spot hasil kurasi manual. Aturan: setiap nilai harus punya sumber;
/// yang tidak ditemukan dibiarkan kosong (tampil "tidak tersedia").
/// Teks ringkasan dan sejarah adalah parafrase bahasa Indonesia dari sumber yang tercantum.
const List<Spot> spotsSeed = [
  Spot(
    id: 'bunaken',
    name: 'Taman Nasional Bunaken',
    region: 'Sulawesi Utara',
    level: SpotLevel.pemula,
    levelBasis: _levelNote,
    types: [SpotType.scuba, SpotType.snorkeling],
    summary:
        'Taman laut di utara Pulau Sulawesi, dekat Manado, yang berada di pusat '
        'Segitiga Terumbu Karang. Luasnya sekitar 890,65 km2 dan 97 persennya laut; '
        'daratannya hanya lima pulau: Bunaken, Manado Tua, Mantehage, Nain, dan Siladen. '
        'Ciri khasnya adalah dinding karang vertikal setinggi 25-50 meter yang dihuni '
        '13 genus karang. Kawasan ini tidak punya paparan benua, sehingga pantainya '
        'langsung turun ke lereng benua; kedalaman laut di antara pulau-pulaunya '
        '200-1.840 meter. Sekitar 390 spesies karang tercatat di sini, dan sekitar 2.000 '
        'spesies ikan hidup di perairannya. Menyelam dan snorkeling adalah kegiatan '
        'wisata utama. Suhu air 27-29 derajat Celsius.',
    history:
        'Bunaken ditetapkan sebagai taman nasional pada 1991 dan termasuk taman laut '
        'pertama di Indonesia. Pada 2005 Indonesia mengajukannya ke UNESCO untuk masuk '
        'Daftar Warisan Dunia. Di dalam kawasan ada sekitar 22 desa dengan kira-kira '
        '35.000 penduduk, kebanyakan nelayan atau petani kelapa dan rumput laut; hanya '
        'sebagian kecil bekerja di pariwisata. Pada 2003-2006 jumlah pengunjung berkisar '
        '32.000-39.000 orang per tahun. Kualitas kawasan menurun perlahan karena '
        'penambangan karang, kerusakan akibat jangkar, penangkapan ikan dengan bom dan '
        'sianida, serta sampah. WWF membantu patroli dan penegakan aturan yang '
        'menurunkan penangkapan ikan dengan bom secara signifikan. Pada 2009 ikan '
        'purba selakanta Indonesia pertama kali difilmkan langsung di alam dekat Manado '
        'Tua, dan pada 2024 inisiatif No-Trash Triangle memasang penghalang sungai di '
        'Manado untuk mengurangi sampah plastik yang masuk ke taman.',
    biota: [
      'Kima raksasa (7 dari 8 spesies dunia)',
      'Ikan malaikat kaisar',
      'Kuda laut tutul',
      'Nautilus berongga',
      'Selakanta Indonesia (difilmkan 2009)',
      'Penyu',
    ],
    latitude: 1.667,
    longitude: 124.650,
    timeZoneLabel: 'WITA',
    sources: [
      'Wikipedia: Bunaken National Park (luas, tahun, dinding karang, sejarah) - https://en.wikipedia.org/wiki/Bunaken_National_Park',
      'Wikipedia: Bunaken (suhu air, kima raksasa) - https://en.wikipedia.org/wiki/Bunaken',
      'UNESCO Tentative List (dasar laut curam) - https://whc.unesco.org/en/tentativelists/2002',
      'Two Fish Divers (menyelam dan snorkeling) - https://oldsite.twofishdivers.com/?p=21104',
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
        'Gugusan sekitar 150 pulau di Sulawesi Tenggara. Nama Wakatobi adalah singkatan '
        'dari empat pulau utamanya: Wangi-wangi, Kaledupa, Tomia, dan Binongko. Wilayahnya '
        'berada di zona keanekaragaman hayati laut Wallacea dan menjadi bagian dari '
        'Segitiga Terumbu Karang. Daratan kabupatennya seluas 473,62 km2, sedangkan '
        'perairannya sekitar 17.554 km2. Taman Nasional Wakatobi seluas sekitar 1,39 juta '
        'hektare dengan kedalaman perairan yang bervariasi hingga titik terdalam sekitar '
        '1.044 meter. Skala dan kondisi terumbu karangnya termasuk prioritas tertinggi '
        'konservasi laut di Indonesia. Lanskap bawah lautnya mencakup atol, dinding, '
        'gunung laut, dan karang penghalang.',
    history:
        'Sebelum kemerdekaan, kepulauan ini berada di bawah Kesultanan Buton dan dikenal '
        'sebagai Kepulauan Tukang Besi. Setelah kemerdekaan, gugusan pulaunya menjadi '
        'beberapa kecamatan di Kabupaten Buton. Kabupaten Wakatobi dibentuk pada 18 '
        'Desember 2003 lewat UU Nomor 29 Tahun 2003, bersama Kabupaten Bombana dan Kolaka '
        'Utara. Kawasan lautnya resmi menjadi taman nasional pada 1996, dan pada 11 Juli '
        '2012 UNESCO memasukkan Wakatobi ke Jaringan Cagar Biosfer Dunia. Di daratan '
        'masih ada peninggalan sejarah seperti Benteng Liya dengan empat lapis dinding, '
        'Benteng Mandati Tonga, dan mercusuar peninggalan Belanda yang dibangun pada '
        '1901. Suku Bajau, pengembara laut yang hidup dari sumber daya laut, juga '
        'tinggal di kawasan ini.',
    latitude: -5.53583,
    longitude: 123.75806,
    timeZoneLabel: 'WITA',
    sources: [
      'Wikipedia: Wakatobi Regency (koordinat, luas, sejarah, cagar biosfer) - https://en.wikipedia.org/wiki/Wakatobi_Regency',
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
        'Raja Ampat atau "Empat Raja" adalah kepulauan di ujung barat laut Semenanjung '
        'Kepala Burung, Pulau Papua, yang sejak 2024 masuk Provinsi Papua Barat Daya. '
        'Terdiri atas lebih dari 1.500 pulau kecil, karang, dan gosong di sekitar empat '
        'pulau utama (Misool, Salawati, Batanta, Waigeo) dan Pulau Kofiau. Kepulauan ini '
        'bagian dari Segitiga Terumbu Karang dan dianggap pusat keanekaragaman hayati '
        'laut tropis dunia: lebih dari 600 spesies karang keras (sekitar 75 persen spesies '
        'dunia) dan lebih dari 1.700 spesies ikan karang. Dugong, paus, lumba-lumba, dan '
        'hiu paus juga ditemukan. Suhu air di Raja Ampat utara 28-30 derajat Celsius, '
        'di selatan (Misool) 26-28 derajat Celsius. Lokasinya terpencil dan relatif '
        'tidak terganggu manusia.',
    history:
        'Bukti arkeologi menunjukkan manusia pertama kali mengunjungi Raja Ampat lebih '
        'dari 50.000 tahun lalu, dan komunitas pembuat gerabah datang sekitar '
        '3.500-3.000 tahun lalu. Nama "Raja Ampat" berasal dari mitos setempat tentang '
        'seorang perempuan yang menemukan tujuh telur; beberapa telur menetas menjadi '
        'raja yang menempati kepulauan ini. Kerajaan yang disebut dalam tradisi antara '
        'lain Waigeo, Salawati, Sailolof, Misool, dan Waigama, dan siapa yang dihitung '
        'sebagai "empat" berbeda menurut sumbernya. Orang Eropa pertama yang tercatat '
        'mendarat adalah navigator Portugis Jorge de Menezes pada 1526. Islam masuk '
        'pada abad ke-15 lewat hubungan dengan Kesultanan Bacan, dan pada abad ke-16 '
        'dan 17 kepulauan ini terkait erat dengan Kesultanan Tidore sebelum diklaim '
        'Belanda. Kabupaten Raja Ampat dibentuk pada 2004 (pemekaran dari Kabupaten '
        'Sorong), Taman Wisata Perairan Raja Ampat ditetapkan pada 2009, dan pada 2025 '
        'UNESCO menetapkannya sebagai cagar biosfer. Ancaman yang tercatat antara lain '
        'bintang laut mahkota duri dan kapal pesiar yang kandas pada Maret 2017 dan '
        'merusak sekitar 1.600 m2 terumbu menurut tim evaluasi. Program pelepasan hiu '
        'zebra dimulai pada 2022 dengan target 500 hiu hingga 2032.',
    biota: [
      'Karang keras (lebih dari 600 spesies)',
      'Ikan karang (lebih dari 1.700 spesies)',
      'Hiu paus',
      'Dugong',
      'Penyu belimbing, lekang, dan sisik',
    ],
    latitude: -0.2333115,
    longitude: 130.5078908,
    timeZoneLabel: 'WIT',
    sources: [
      'Wikipedia: Raja Ampat Islands (koordinat, keanekaragaman, sejarah) - https://www.wikipedia.org/wiki/Raja_Ampat',
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
        'Taman nasional di antara Pulau Sumbawa dan Flores, ditetapkan UNESCO sebagai '
        'Warisan Dunia pada 1991 dengan luas 219.322 hektare. Selain menjadi habitat '
        'biawak komodo, perairannya memiliki terumbu karang yang kaya dan disebut '
        'disapu arus dengan banyak satwa pelagis. Penjelasan dan sejarah yang lebih '
        'lengkap menyusul pada pembaruan data berikutnya.',
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
  Spot(
    id: 'karimunjawa',
    name: 'Kepulauan Karimunjawa',
    region: 'Jawa Tengah',
    level: SpotLevel.pemula,
    levelBasis: _levelNote,
    types: [SpotType.snorkeling],
    summary:
        'Kepulauan berisi 27 pulau di Laut Jawa, sekitar 80 km barat laut Jepara, Jawa '
        'Tengah, dengan luas daratan total 45,62 km2. Pulau utamanya Karimun (2.700 '
        'hektare) dan yang terbesar kedua Kemujan (1.400 hektare). Penduduknya 9.789 '
        'jiwa (Sensus 2020) di lima pulau; budaya Jawa dominan, dan ini satu-satunya '
        'gugusan pulau lepas pantai Jawa yang berbahasa pengantar Jawa. Dua puluh dua '
        'pulau menjadi kawasan konservasi laut Taman Nasional Karimunjawa. Pulau-pulaunya '
        'dikelilingi terumbu karang tepi dan terumbu karang yang tersebar, ditambah '
        'padang lamun; penyu sisik dan penyu hijau ditemukan di sini. Wisatawan dapat '
        'menyewa perahu untuk mengelilingi pulau dan snorkeling.',
    history:
        'Menurut legenda, nama Karimunjawa berasal dari ungkapan Jawa "kremun-kremun '
        'soko Jowo" yang berarti "tampak samar dari Jawa". Sejarah permukimannya dikaitkan '
        'dengan penyebaran Islam di Jawa: Amir Hasan (Sunan Nyamplungan), putra Sunan '
        'Muria, disebut sebagai penemu yang menetap, dan makamnya di bukit Pulau '
        'Karimunjawa dianggap titik keramat (sumber wisata, berupa tradisi tutur). '
        'Wikipedia mencatat gugusan ini dinyatakan sebagai taman nasional pada 1988, '
        'dan 22 pulaunya ditetapkan sebagai cagar laut pada 2001; kedua tahun tertulis '
        'di sumber yang sama, jadi sebaiknya dicek ke sumber resmi sebelum dikutip '
        'di laporan.',
    biota: ['Penyu sisik', 'Penyu hijau', 'Padang lamun'],
    latitude: -5.81917,
    longitude: 110.459,
    timeZoneLabel: 'WIB',
    sources: [
      'Wikipedia: Karimunjawa (koordinat, luas, penduduk, sejarah penetapan) - https://en.wikipedia.org/wiki/Karimunjawa',
      'Wikipedia: Karimunjawa National Park (penyu, lamun) - https://en.wikipedia.org/wiki/Karimunjawa_National_Park',
      'Kupi.com (asal nama, tradisi tutur) - https://www.kupi.com/en/explore/indonesia/karimunjawa/history',
      'Kemenparekraf (snorkeling, perahu) - https://bob.kemenparekraf.go.id/en/1927-pulau-karimunjawa',
      'DBpedia (zona waktu UTC+7) - https://dbpedia.org/page/Karimunjawa',
    ],
  ),
  Spot(
    id: 'derawan',
    name: 'Kepulauan Derawan',
    region: 'Kalimantan Timur',
    level: SpotLevel.menengah,
    levelBasis: _levelNote,
    types: [SpotType.scuba],
    summary:
        'Kepulauan di Provinsi Kalimantan Timur yang terdiri atas 31 pulau; yang paling '
        'dikenal adalah Derawan, Kakaban, Maratua, dan Sangalaki. Kawasan ini berada di '
        'hotspot keanekaragaman hayati dengan 872 spesies ikan karang serta 507 spesies '
        'karang dan invertebrata, termasuk satwa dilindungi seperti 5 spesies kima '
        'raksasa, 2 spesies penyu, dan kepiting kelapa. Hanya dua pulau yang '
        'berpenghuni: Derawan (1.259 jiwa) dan Maratua (2.704 jiwa). Ada tiga resor '
        'selam di kepulauan ini. Koordinat dan sejarah menyusul pada pembaruan data berikutnya.',
    biota: [
      'Ikan karang (872 spesies)',
      'Karang dan invertebrata (507 spesies)',
      'Kima raksasa (5 spesies)',
      'Penyu (2 spesies)',
      'Kepiting kelapa',
    ],
    timeZoneLabel: 'WITA',
    sources: [
      'Wikipedia: Derawan Islands (jumlah pulau, keanekaragaman, penduduk) - https://en.wikipedia.org/wiki/Derawan_Islands',
      _timeZoneNote,
    ],
  ),
];
