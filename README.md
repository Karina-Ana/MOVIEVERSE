# MOVIEVERSE 🎬

**Aplikasi Katalog Film Berbasis Flutter**

MOVIEVERSE adalah aplikasi mobile berbasis Flutter dan Dart yang dirancang untuk membantu pengguna menjelajahi katalog film, mencari film berdasarkan kata kunci, melihat informasi detail, dan menyimpan film favorit. Aplikasi ini menggunakan API untuk mengambil data film secara dinamis dan menampilkannya dalam antarmuka bertema gelap.

## ✨ Fitur Utama

- **Katalog Film** — Menampilkan daftar film beserta poster, judul, tahun rilis, dan rating jika tersedia.
- **Pencarian Film** — Mencari film berdasarkan kata kunci.
- **Filter Genre** — Menyaring daftar film berdasarkan genre.
- **Pengurutan Film** — Mengurutkan film berdasarkan:
  - Popular — popularitas tertinggi.
  - Top Rated — rating tertinggi.
  - Title A–Z — judul secara alfabetis.
- **Detail Film** — Menampilkan informasi film, seperti sinopsis, poster, tahun rilis, durasi, genre, rating, sutradara, pemeran, dan informasi lain yang tersedia dari API.
- **Daftar Favorit** — Menambahkan atau menghapus film favorit dan menyimpan pilihan secara lokal.
- **Informasi Pemeran** — Mengambil gambar pemeran dari Wikipedia apabila tersedia.
- **Trailer Film** — Membuka tautan trailer eksternal apabila tersedia.
- **Tema Gelap** — Menggunakan desain antarmuka bertema gelap.
- **Penanganan Proses Asinkron** — Menampilkan kondisi loading, data, dan kesalahan saat mengambil data.

## 🛠️ Teknologi dan Package

| Teknologi / Package | Kegunaan |
|---|---|
| Flutter | Framework untuk membangun antarmuka aplikasi mobile. |
| Dart | Bahasa pemrograman aplikasi. |
| `http` | Mengirim permintaan HTTP ke API. |
| `shared_preferences` | Menyimpan daftar favorit secara lokal. |
| `url_launcher` | Membuka tautan trailer melalui aplikasi eksternal. |
| `cupertino_icons` | Menyediakan ikon bergaya Cupertino. |
| `flutter_test` | Mendukung pengujian aplikasi Flutter. |
| `flutter_lints` | Membantu menjaga kualitas dan konsistensi kode. |

Package `json_annotation`, `build_runner`, dan `json_serializable` juga tercantum dalam konfigurasi proyek sebagai dependency tambahan untuk kebutuhan serialisasi dan pengembangan.

## 🌐 Sumber Data API

MOVIEVERSE menggunakan sumber data eksternal berikut:

**1. Cinemeta Catalog API**

Digunakan untuk mengambil katalog film.

https://cinemeta-catalogs.strem.io/top/catalog/movie/top.json

**2. Cinemeta API**

Digunakan untuk mengambil informasi detail film berdasarkan ID IMDb.

https://v3-cinemeta.strem.io/

Format endpoint detail film:

```text
https://v3-cinemeta.strem.io/meta/movie/{imdb_id}.json
```

`{imdb_id}` merupakan ID IMDb film yang dipilih.

**3. Wikipedia REST API**

Digunakan untuk mencari gambar pemeran apabila tersedia.

https://en.wikipedia.org/api/rest_v1/

Data dari API diterima dalam format JSON, kemudian diproses menjadi objek Dart menggunakan class model `Movie` sebelum ditampilkan pada antarmuka aplikasi.

## 📁 Struktur Proyek

```text
lib/
├── model/
│   └── movie.dart
├── view/
│   ├── app_colors.dart
│   ├── detail.dart
│   ├── favorites.dart
│   └── home.dart
├── viewmodel/
│   ├── favorites_store.dart
│   └── fetchmovie.dart
└── main.dart

test/
└── widget_test.dart

pubspec.yaml
README.md
```

**Penjelasan direktori:**

- `model/` — Menyimpan class model untuk merepresentasikan data film.
- `view/` — Berisi halaman aplikasi dan pengaturan warna antarmuka.
- `viewmodel/` — Mengelola pengambilan data API dan penyimpanan favorit.
- `main.dart` — Titik masuk aplikasi dan konfigurasi tema serta navigasi.
- `test/` — Menyimpan berkas pengujian aplikasi.
- `pubspec.yaml` — Mengatur dependency dan konfigurasi proyek Flutter.

## 🚀 Cara Menjalankan Aplikasi

### Persyaratan

Pastikan perangkat pengembangan telah memiliki:

- Flutter SDK.
- Dart SDK yang sesuai dengan persyaratan proyek Flutter.
- Android Studio atau Visual Studio Code.
- Emulator Android atau perangkat Android fisik.
- Koneksi internet untuk mengambil data dari API.

### Langkah Instalasi

**1. Clone repositori**

```bash
git clone <URL_REPOSITORY_GITHUB>
```

Ganti `<URL_REPOSITORY_GITHUB>` dengan URL repositori GitHub milikmu.

**2. Masuk ke direktori proyek**

```bash
cd <NAMA_FOLDER_PROYEK>
```

**3. Unduh dependency**

```bash
flutter pub get
```

**4. Periksa konfigurasi Flutter**

```bash
flutter doctor
```

**5. Jalankan aplikasi**

Pastikan emulator atau perangkat telah terhubung, lalu jalankan:

```bash
flutter run
```

## 🧪 Pengujian

Untuk menjalankan pengujian yang tersedia dalam proyek, gunakan perintah:

```bash
flutter test
```

Untuk memeriksa masalah statis pada kode, jalankan:

```bash
flutter analyze
```

Hasil pengujian dan analisis bergantung pada kondisi kode serta lingkungan pengembangan.

## 📌 Catatan

- Aplikasi membutuhkan koneksi internet untuk mengambil data film dan gambar pemeran dari API.
- Kelengkapan informasi film bergantung pada data yang disediakan oleh API.
- Gambar pemeran, poster, atau trailer mungkin tidak tersedia untuk semua film.
- Daftar favorit disimpan secara lokal menggunakan `shared_preferences`.
- Cinemeta dan Wikipedia merupakan layanan eksternal yang tidak dikelola oleh aplikasi MOVIEVERSE.

## 👨‍💻 Tujuan Proyek

MOVIEVERSE dikembangkan sebagai proyek Ujian Tengah Semester (UTS) mata kuliah Pemrograman Mobile. Proyek ini menerapkan pengembangan antarmuka menggunakan Flutter, pengambilan dan pengolahan data API, pemrograman asinkron, penggunaan class model Dart, serta penyimpanan data lokal.

---

**MOVIEVERSE — Explore Movies, Discover Stories.**
