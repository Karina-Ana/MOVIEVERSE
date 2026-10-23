# 🎬 MOVIEVERSE

**MOVIEVERSE** adalah aplikasi katalog film berbasis mobile yang dikembangkan menggunakan Flutter dan bahasa pemrograman Dart. Aplikasi ini membantu pengguna mencari, menjelajahi, dan melihat informasi film dalam satu tempat melalui data yang diperoleh dari API.

MOVIEVERSE memiliki antarmuka bertema gelap (*dark theme*), fitur pencarian dan penyaringan film, halaman detail, serta daftar film favorit yang dapat disimpan untuk diakses kembali.

## ✨ Fitur Utama

- **Katalog Film** — Menampilkan daftar film beserta poster dan informasi film yang diperoleh dari API.
- **Pencarian Film** — Memudahkan pengguna menemukan film berdasarkan kata kunci.
- **Filter Genre** — Menyaring daftar film berdasarkan genre.
- **Pengurutan Film** — Mengurutkan film berdasarkan:
  - `Popular` — Popularitas tertinggi.
  - `Top Rated` — Rating tertinggi.
  - `Title A–Z` — Judul film berdasarkan urutan alfabet.
- **Detail Film** — Menampilkan informasi lebih lengkap, seperti judul, poster, deskripsi, tahun rilis, durasi, rating, genre, dan informasi pemeran sesuai data yang tersedia.
- **Film Favorit** — Menyimpan film pilihan agar dapat diakses kembali melalui halaman Favorites.
- **Trailer Film** — Menyediakan tautan untuk membuka trailer film melalui YouTube.
- **Dark Theme** — Menggunakan tema gelap untuk menjaga konsistensi tampilan aplikasi.
- **Pull-to-Refresh** — Memuat ulang katalog film melalui gerakan menarik halaman ke bawah.
- **Status Data** — Menampilkan indikator loading serta penanganan kondisi error dan data kosong.

## 📸 Tangkapan Layar Aplikasi

### 1. Halaman Home

Menampilkan katalog film, kolom pencarian, pilihan pengurutan, dan filter genre.


<img width="270" height="642" alt="image" src="https://github.com/user-attachments/assets/1bb00421-3c62-4a72-bc2d-f9d0b3082056" />


### 2. Pencarian dan Filter Genre

Menampilkan fitur pencarian film berdasarkan kata kunci dan penyaringan film berdasarkan genre.

![Pencarian dan Filter Genre MOVIEVERSE](screenshots/search-filter.png)

### 3. Pengurutan Film

Menampilkan pilihan pengurutan film berdasarkan Popular, Top Rated, dan Title A–Z.

![Pengurutan Film MOVIEVERSE](screenshots/sorting.png)

### 4. Halaman Detail Film

Menampilkan informasi film yang dipilih, seperti poster, judul, deskripsi, tahun rilis, durasi, rating, genre, dan informasi lainnya sesuai data yang tersedia.

![Detail Film MOVIEVERSE](screenshots/detail.png)

### 5. Halaman Favorites

Menampilkan daftar film yang telah disimpan oleh pengguna sebagai film favorit.

![Favorites MOVIEVERSE](screenshots/favorites.png)

### 6. Trailer Film

Menampilkan bagian atau tombol trailer pada halaman detail film yang dapat digunakan untuk membuka video trailer melalui YouTube.

![Trailer Film MOVIEVERSE](screenshots/trailer.png)

## 🛠️ Teknologi dan Package

| Teknologi / Package | Kegunaan |
|---|---|
| Flutter | Framework untuk membangun aplikasi mobile. |
| Dart | Bahasa pemrograman aplikasi. |
| API | Sumber data katalog dan detail film. |
| `http` | Mengirim permintaan HTTP untuk mengambil data dari API. |
| `shared_preferences` | Menyimpan data lokal sederhana, termasuk data favorit sesuai implementasi aplikasi. |
| `url_launcher` | Membuka tautan trailer film melalui aplikasi atau browser yang mendukungnya. |
| `dart:convert` | Mengolah respons JSON menjadi data yang dapat digunakan aplikasi. |

## 📂 Struktur Proyek

Struktur file utama aplikasi MOVIEVERSE:

```text
lib/
├── main.dart
├── movie.dart
├── home.dart
├── detail.dart
├── favorites.dart
├── favorites_store.dart
├── fetchmovie.dart
└── app_colors.dart

pubspec.yaml
README.md
```

Keterangan:

- `main.dart` — Titik masuk aplikasi dan konfigurasi tema.
- `movie.dart` — Model data film dan proses pemetaan data JSON.
- `home.dart` — Halaman utama yang menampilkan katalog, pencarian, filter, dan pengurutan film.
- `detail.dart` — Halaman detail film dan informasi terkait.
- `favorites.dart` — Halaman daftar film favorit.
- `favorites_store.dart` — Pengelolaan penyimpanan data film favorit.
- `fetchmovie.dart` — Pengambilan dan pemrosesan data film dari API.
- `app_colors.dart` — Pengaturan warna aplikasi.
- `pubspec.yaml` — Konfigurasi proyek dan dependensi package.

## 🚀 Cara Menjalankan Aplikasi

### 1. Persiapan

Pastikan perangkat pengembangan telah memiliki:

- Flutter SDK.
- Dart SDK yang sesuai dengan versi Flutter.
- Android Studio atau Visual Studio Code.
- Android Emulator atau perangkat Android untuk menjalankan aplikasi.
- Git, jika ingin mengkloning repositori.

### 2. Clone Repositori

Buka terminal, kemudian jalankan perintah berikut:

```bash
git clone <URL_REPOSITORI_GITHUB>
```

Masuk ke direktori proyek:

```bash
cd MOVIEVERSE
```

Ganti `<URL_REPOSITORI_GITHUB>` dengan URL repositori GitHub milik Anda.

### 3. Instal Dependensi

Jalankan perintah berikut untuk mengunduh package yang dibutuhkan:

```bash
flutter pub get
```

### 4. Periksa Konfigurasi Flutter

Pastikan instalasi Flutter telah siap:

```bash
flutter doctor
```

Selesaikan masalah konfigurasi yang dilaporkan jika diperlukan.

### 5. Jalankan Aplikasi

Hubungkan perangkat Android atau nyalakan emulator, lalu jalankan:

```bash
flutter run
```

Aplikasi MOVIEVERSE akan dibangun dan dijalankan pada perangkat yang dipilih.

### 6. Build APK (Opsional)

Untuk membuat file APK yang dapat dipasang pada perangkat Android, jalankan:

```bash
flutter build apk --release
```

Jika proses build berhasil, file APK biasanya tersedia di:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## 📱 Penggunaan Aplikasi

1. Buka aplikasi MOVIEVERSE.
2. Jelajahi katalog film pada halaman Home.
3. Gunakan kolom pencarian untuk mencari film berdasarkan kata kunci.
4. Gunakan filter genre atau pilihan pengurutan untuk menyesuaikan daftar film.
5. Pilih film untuk melihat informasi detailnya.
6. Gunakan fitur trailer untuk membuka video trailer melalui YouTube.
7. Simpan film yang diinginkan ke Favorites agar mudah ditemukan kembali.

## 🎓 Informasi Proyek

- **Nama Aplikasi:** MOVIEVERSE
- **Jenis Aplikasi:** Katalog film berbasis mobile
- **Framework:** Flutter
- **Bahasa Pemrograman:** Dart
- **Mata Kuliah:** Pemrograman Mobile
- **Jenis Proyek:** Ujian Tengah Semester (UTS)

## 📄 Lisensi

Proyek ini dibuat untuk keperluan pembelajaran dan pengembangan aplikasi mobile. Pastikan penggunaan data, API, gambar poster, dan materi film mengikuti ketentuan dari penyedia masing-masing.
