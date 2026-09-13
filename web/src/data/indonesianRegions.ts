// Daftar Provinsi dan Kota/Kabupaten di Indonesia
export interface Province {
  name: string
  cities: string[]
}

export const provinces: Province[] = [
  {
    name: 'Aceh',
    cities: [
      'Banda Aceh', 'Langsa', 'Lhokseumawe', 'Sabang', 'Subulussalam',
      'Aceh Barat', 'Aceh Barat Daya', 'Aceh Besar', 'Aceh Jaya', 'Aceh Selatan',
      'Aceh Singkil', 'Aceh Tamiang', 'Aceh Tengah', 'Aceh Tenggara', 'Aceh Timur',
      'Aceh Utara', 'Bireuen', 'Gayo Lues', 'Nagan Raya', 'Pidie', 'Pidie Jaya', 'Simeulue',
    ],
  },
  {
    name: 'Sumatera Utara',
    cities: [
      'Binjai', 'Gunung Sitoli', 'Medan', 'Padang Sidempuan', 'Pematangsiantar', 'Sibolga', 'Tanjung Balai', 'Tebing Tinggi',
      'Asahan', 'Batubara', 'Dairi', 'Deli Serdang', 'Humbang Hasundutan', 'Karo', 'Labuhanbatu', 'Labuhanbatu Selatan',
      'Labuhanbatu Utara', 'Langkat', 'Mandailing Natal', 'Nias', 'Nias Barat', 'Nias Selatan', 'Nias Utara', 'Padang Lawas',
      'Padang Lawas Utara', 'Pakpak Bharat', 'Samosir', 'Serdang Bedagai', 'Simalungun', 'Tapanuli Selatan', 'Tapanuli Tengah',
      'Tapanuli Utara', 'Toba',
    ],
  },
  {
    name: 'Sumatera Barat',
    cities: [
      'Bukittinggi', 'Padang', 'Padang Panjang', 'Pariaman', 'Payakumbuh', 'Sawahlunto', 'Solok',
      'Agam', 'Dharmasraya', 'Kepulauan Mentawai', 'Lima Puluh Kota', 'Padang Pariaman', 'Pasaman', 'Pasaman Barat',
      'Pesisir Selatan', 'Sijunjung', 'Solok', 'Solok Selatan', 'Tanah Datar',
    ],
  },
  {
    name: 'Riau',
    cities: [
      'Dumai', 'Pekanbaru',
      'Bengkalis', 'Indragiri Hilir', 'Indragiri Hulu', 'Kampar', 'Kepulauan Meranti', 'Kuantan Singingi',
      'Pelalawan', 'Rokan Hilir', 'Rokan Hulu', 'Siak',
    ],
  },
  {
    name: 'Kepulauan Riau',
    cities: [
      'Batam', 'Tanjung Pinang',
      'Bintan', 'Karimun', 'Kepulauan Anambas', 'Lingga', 'Natuna',
    ],
  },
  {
    name: 'Jambi',
    cities: [
      'Jambi', 'Sungai Penuh',
      'Batanghari', 'Bungo', 'Kerinci', 'Merangin', 'Muaro Jambi', 'Sarolangun', 'Tanjung Jabung Barat',
      'Tanjung Jabung Timur', 'Tebo',
    ],
  },
  {
    name: 'Sumatera Selatan',
    cities: [
      'Lubuklinggau', 'Pagar Alam', 'Palembang', 'Prabumulih',
      'Banyuasin', 'Empat Lawang', 'LAHAT', 'Muara Enim', 'Musi Banyuasin', 'Musi Rawas',
      'Musi Rawas Utara', 'Ogan Ilir', 'Ogan Komering Ilir', 'Ogan Komering Ulu', 'Ogan Komering Ulu Selatan',
      'Ogan Komering Ulu Timur', 'Penukal Abang Lematang Ilir',
    ],
  },
  {
    name: 'Bengkulu',
    cities: [
      'Bengkulu', 'Bengkulu Selatan', 'Bengkulu Tengah', 'Bengkulu Utara', 'Kaur', 'Kepahiang',
      'Lebong', 'Mukomuko', 'Rejang Lebong', 'Seluma',
    ],
  },
  {
    name: 'Lampung',
    cities: [
      'Bandar Lampung', 'Metro',
      'Lampung Barat', 'Lampung Selatan', 'Lampung Tengah', 'Lampung Timur', 'Lampung Utara',
      'Mesuji', 'Pesawaran', 'Pesisir Barat', 'Pringsewu', 'Tanggamus', 'Tulang Bawang',
      'Tulang Bawang Barat', 'Way Kanan',
    ],
  },
  {
    name: 'Kepulauan Bangka Belitung',
    cities: [
      'Pangkal Pinang',
      'Bangka', 'Bangka Barat', 'Bangka Selatan', 'Bangka Tengah', 'Belitung', 'Belitung Timur',
    ],
  },
  {
    name: 'DKI Jakarta',
    cities: [
      'Jakarta Barat', 'Jakarta Pusat', 'Jakarta Selatan', 'Jakarta Timur', 'Jakarta Utara',
      'Kepulauan Seribu',
    ],
  },
  {
    name: 'Jawa Barat',
    cities: [
      'Bandung', 'Bekasi', 'Bogor', 'Cimahi', 'Cirebon', 'Depok', 'Sukabumi', 'Tasikmalaya',
      'Banjar', 'Indramayu', 'Karawang', 'Kuningan', 'Majalengka', 'Purwakarta', 'Subang', 'Sumedang',
    ],
  },
  {
    name: 'Jawa Tengah',
    cities: [
      'Magelang', 'Pekalongan', 'Salatiga', 'Semarang', 'Surakarta', 'Tegal',
      'Banjarnegara', 'Banyumas', 'Batang', 'Blora', 'Boyolali', 'Brebes', 'Cilacap', 'Demak',
      'Grobogan', 'Jepara', 'Karanganyar', 'Kebumen', 'Kendal', 'Klaten', 'Kudus', 'Pati',
      'Pemalang', 'Purbalingga', 'Purworejo', 'Rembang', 'Sragen', 'Sukoharjo', 'Temanggung', 'Wonogiri', 'Wonosobo',
    ],
  },
  {
    name: 'DI Yogyakarta',
    cities: [
      'Bantul', 'Godean', 'Sleman', 'Yogyakarta',
      'Gunung Kidul', 'Kulon Progo',
    ],
  },
  {
    name: 'Jawa Timur',
    cities: [
      'Batubara', 'Blitar', 'Banyuwangi', 'Gresik', 'Jember', 'Kediri', 'Lumajang', 'Madiun',
      'Malang', 'Mojokerto', 'Pasuruan', 'Probolinggo', 'Sidoarjo', 'Surabaya', 'Tulungagung',
      'Bangkalan', 'Bojonegoro', 'Bondowos', 'Jombang', 'Kepulauan S', 'Lamongan', 'Magetan',
      'Nganjuk', 'Ngawi', 'Pacitan', 'Pamekasan', 'Ponorogo', 'Situbondo', 'Sumenep', 'Trenggalek',
    ],
  },
  {
    name: 'Banten',
    cities: [
      'Cilegon', 'Serang', 'Tangerang', 'Tangerang Selatan',
      'Lebak', 'Pandeglang',
    ],
  },
  {
    name: 'Bali',
    cities: [
      'Denpasar',
      'Badung', 'Bangli', 'Buleleng', 'Gianyar', 'Jembrana', 'Karangasem', 'Klungkung', 'Tabanan',
    ],
  },
  {
    name: 'Nusa Tenggara Barat',
    cities: [
      'Bima', 'Mataram',
      'Bima', 'Dompu', 'Lombok Barat', 'Lombok Tengah', 'Lombok Timur', 'Lombok Utara', 'Sumbawa', 'Sumbawa Barat',
    ],
  },
  {
    name: 'Nusa Tenggara Timur',
    cities: [
      'Kupang',
      'Alor', 'Belu', 'Ende', 'Flores Timur', 'Kupang', 'Lembata', 'Manggarai', 'Manggarai Barat',
      'Manggarai Timur', 'Nagekeo', 'Ngada', 'Rote Ndao', 'Sabu Raijua', 'Sikka', 'Sumba Barat',
      'Sumba Barat Daya', 'Sumba Tengah', 'Sumba Timur', 'Timor Tengah Selatan', 'Timor Tengah Utara',
    ],
  },
  {
    name: 'Kalimantan Barat',
    cities: [
      'Pontianak',
      'Bengkayang', 'Kapuas Hulu', 'Kayong Utara', 'Ketapang', 'Kubu Raya', 'Landak', 'Melawi',
      'Pontianak', 'Sambas', 'Sanggau', 'Sekadau', 'Sintang',
    ],
  },
  {
    name: 'Kalimantan Tengah',
    cities: [
      'Palangkaraya',
      'Barito Selatan', 'Barito Timur', 'Barito Utara', 'Gunung Mas', 'Kapuas', 'Katingan', 'Kotawaringin Barat',
      'Kotawaringin Timur', 'Lamandau', 'Murung Raya', 'Pandang Pandang', 'Pulang Pisau', 'Sukamara', 'Seruyan',
    ],
  },
  {
    name: 'Kalimantan Selatan',
    cities: [
      'Banjar', 'Banjarbaru', 'Banjarmasin', 'Barabai', 'Martapura',
      'Balangan', 'Banjar', 'Barito Kuala', 'Hulu Sungai Selatan', 'Hulu Sungai Tengah',
      'Hulu Sungai Utara', 'Kotabaru', 'Tabalong', 'Tanah Bumbu', 'Tanah Laut', 'Tapin',
    ],
  },
  {
    name: 'Kalimantan Timur',
    cities: [
      'Balikpapan', 'Bontang', 'Samarinda',
      'Berau', 'Kutai Barat', 'Kutai Kartanegara', 'Kutai Timur', 'Mahakam Ulu', 'Paser', 'Penajam Paser Utara',
    ],
  },
  {
    name: 'Kalimantan Utara',
    cities: [
      'Tarakan',
      'Bulungan', 'Malinau', 'Nunukan', 'Tana Tidung',
    ],
  },
  {
    name: 'Sulawesi Utara',
    cities: [
      'Bitung', 'Kotamobagu', 'Manado', 'Tomohon',
      'Bolaang Mongondow', 'Bolaang Mongondow Selatan', 'Bolaang Mongondow Timur',
      'Bolaang Mongondow Utara', 'Kepulauan Sangihe', 'Kepulauan Siau Tagulandang Biaro',
      'Kepulauan Talaud', 'Minahasa', 'Minahasa Selatan', 'Minahasa Tenggara', 'Minahasa Utara',
    ],
  },
  {
    name: 'Sulawesi Tengah',
    cities: [
      'Palu',
      'Banggai', 'Banggai Kepulauan', 'Banggai Laut', 'Buol', 'Donggala', 'Morowali', 'Morowali Utara',
      'Parigi Moutong', 'Pinrang', 'Poso', 'Sigi', 'Tojo Una-Una', 'Toli-Toli',
    ],
  },
  {
    name: 'Sulawesi Selatan',
    cities: [
      'Makassar', 'Palopo', 'Parepare',
      'Banta', 'Barru', 'Bone', 'Bulukumba', 'Enrekang', 'Gowa', 'Jeneponto', 'Kepulauan Selayar',
      'Luwu', 'Luwu Timur', 'Luwu Utara', 'Maros', 'Pinrang', 'Sidenreng Rappang', 'Sinjai', 'Soppeng',
      'Takalar', 'Tana Toraja', 'Toraja Utara', 'Wajo',
    ],
  },
  {
    name: 'Sulawesi Tenggara',
    cities: [
      'Bau-Bau', 'Kendari',
      'Bombana', 'Buton', 'Buton Selatan', 'Buton Tengah', 'Buton Utara', 'Kolaka', 'Kolaka Timur',
      'Kolaka Utara', 'Konawe', 'Konawe Kepulauan', 'Konawe Selatan', 'Konawe Utara', 'Muna', 'Muna Barat',
      'Wakatobi',
    ],
  },
  {
    name: 'Gorontalo',
    cities: [
      'Gorontalo',
      'Boalemo', 'Bone Bolango', 'Gorontalo Utara', 'Pohuwato',
    ],
  },
  {
    name: 'Sulawesi Barat',
    cities: [
      'Mamuju', 'Mamuju Utara',
      'Majene', 'Mamasa', 'Mamuju', 'Mamuju Tengah', 'Polewali Mandar',
    ],
  },
  {
    name: 'Maluku',
    cities: [
      'Ambon', 'Tual',
      'Buru', 'Buru Selatan', 'Kepulauan Aru', 'Maluku Barat Daya', 'Maluku Tengah',
      'Maluku Tenggara', 'Maluku Tenggara Barat', 'Seram Bagian Barat', 'Seram Bagian Timur',
    ],
  },
  {
    name: 'Maluku Utara',
    cities: [
      'Sofifi', 'Ternate', 'Tidore Kepulauan',
      'Halmahera Barat', 'Halmahera Selatan', 'Halmahera Tengah', 'Halmahera Timur', 'Halmahera Utara',
      'Kepulauan Sula', 'Pulau Morotai', 'Pulau Taliabu',
    ],
  },
  {
    name: 'Papua Barat',
    cities: [
      'Manokwari', 'Sorong',
      'Fakfak', 'Kaimana', 'Manokwari Selatan', 'Pegunungan Arfak', 'Sorong', 'Sorong Selatan',
      'Tambrauw', 'Teluk Bintuni', 'Teluk Wondama',
    ],
  },
  {
    name: 'Papua',
    cities: [
      'Jayapura',
      'Biak Numfor', 'Keerom', 'Mamberamo Raya', 'Mamberamo Tengah', 'Puncak Jaya',
      'Sarmi', 'Supiori', 'Waropen', 'Yahukimo', 'Yalimo',
    ],
  },
  {
    name: 'Papua Selatan',
    cities: [
      'Merauke',
      'Boven Digoel', 'Mappi', 'Merauke',
    ],
  },
  {
    name: 'Papua Tengah',
    cities: [
      'Nabire',
      'Deiyai', 'Dogiyai', 'Intan Jaya', 'Mimika', 'Nabire', 'Paniai', 'Puncak',
    ],
  },
  {
    name: 'Papua Pegunungan',
    cities: [
      'Wamena',
      'Jayawijaya', 'Lanny Jaya', 'Mamberamo Tengah', 'Pegunungan Bintang', 'Tolikara',
      'Yahukimo', 'Yalimo',
    ],
  },
  {
    name: 'Papua Barat Daya',
    cities: [
      'Sorong',
      'Maybrat', 'Raja Ampat', 'Sorong', 'Sorong Selatan', 'Tambrauw',
    ],
  },
  {
    name: 'Papua Barat Tengah',
    cities: [
      'Manokwari',
      'Fakfak', 'Kaimana', 'Manokwari', 'Manokwari Selatan', 'Teluk Bintuni', 'Teluk Wondama',
    ],
  },
  {
    name: 'Papua Barat Utara',
    cities: [
      'Sorong',
      'Halmahera', 'Sorong', 'Ternate',
    ],
  },
]

// Flatten for easy searching
export const allCities: string[] = provinces.flatMap((p) => p.cities)

// Get cities for a specific province
export function getCitiesForProvince(provinceName: string): string[] {
  const province = provinces.find((p) => p.name === provinceName)
  return province ? province.cities : []
}

// Search provinces
export function searchProvinces(query: string): Province[] {
  if (!query) return provinces
  const lower = query.toLowerCase()
  return provinces.filter((p) => p.name.toLowerCase().includes(lower))
}

// Search cities within a province
export function searchCities(provinceName: string, query: string): string[] {
  const cities = getCitiesForProvince(provinceName)
  if (!query) return cities
  const lower = query.toLowerCase()
  return cities.filter((c) => c.toLowerCase().includes(lower))
}
