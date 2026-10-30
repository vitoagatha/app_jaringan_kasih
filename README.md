<p align="center">
  <img src="assets/images/icon_splash.png" alt="Logo Jaringan Kasih" width="220" />
</p>

<h1 align="center">Jaringan Kasih</h1>

<p align="center">Semua dapat membantu.</p>

Jaringan Kasih adalah project aplikasi mobile bertema pendanaan sosial. Aplikasi ini dikembangkan sebagai sarana belajar membangun Flutter yang terhubung ke backend Laravel, mulai dari autentikasi dan pengelolaan akun hingga publikasi pendanaan serta penyimpanan gambar.

Pengguna dapat menemukan pendanaan berdasarkan kategori, menyimpan pendanaan ke wishlist, dan membuat pendanaan sendiri dengan foto serta informasi kegiatan.

## Fitur yang tersedia

| Bagian | Fitur |
| --- | --- |
| Pembukaan aplikasi | Splash screen, onboarding sekali setelah data aplikasi masih baru, dan penentuan layar berdasarkan sesi login. |
| Autentikasi | Registrasi, login, logout, penyimpanan token, serta pemulihan sesi. |
| Akun dan profil | Pembaruan nama/email, verifikasi email, perubahan password, reset password, serta unggah dan hapus foto profil. |
| Beranda | Menu kategori dalam grid tiga kolom, daftar pendanaan, dan akses ke fitur utama. |
| Pendanaan | Membuat dan mengedit pendanaan milik sendiri, status draft/published, target dana, deskripsi, foto, daftar, dan detail pendanaan. |
| Penelusuran | Pencarian judul, filter kategori, filter status pada pendanaan sendiri, dan pagination. |
| Wishlist | Menyimpan dan menghapus pendanaan dari daftar favorit. |
| Penanganan kondisi aplikasi | Indikator loading, pesan validasi, penanganan kegagalan koneksi, dan pilihan mencoba ulang pada layar terkait. |

Kategori awal meliputi **Pendidikan**, **Kesehatan**, **Zakat**, **Lingkungan**, **Rumah Ibadah**, dan **Bencana Alam**.

## Alur aplikasi

Pada pembukaan aplikasi, splash screen ditampilkan saat status onboarding dan sesi diperiksa. Pengguna yang belum menyelesaikan onboarding akan melihat pengenalan singkat aplikasi. Setelah menekan **Mulai sekarang** atau **Lewati**, onboarding tidak ditampilkan lagi pada pembukaan berikutnya selama statusnya masih tersimpan.

Pengguna tanpa sesi diarahkan ke halaman login atau pendaftaran. Jika sesi masih valid, aplikasi membuka beranda. Navigasi utama terdiri dari **Beranda**, **Jelajahi**, **Wishlist**, dan **Akun**. Dari akun, pengguna juga dapat mengakses pengelolaan pendanaan miliknya.

## Teknologi

| Komponen | Teknologi |
| --- | --- |
| Aplikasi | Flutter, Dart, dan Material 3 |
| Backend | PHP 8.2+, Laravel 12, dan REST API |
| Autentikasi API | Laravel Sanctum dengan bearer token |
| Database | PostgreSQL 17 |
| Penyimpanan sesi perangkat | `flutter_secure_storage` |
| Pemilihan gambar | `image_picker` |
| Penyimpanan gambar | Filesystem lokal backend Laravel |
| Email pengembangan | Mailpit |
| Lingkungan backend lokal | Docker Compose |
| Pengujian otomatis | Flutter Test dan PHPUnit |

Implementasi aktif menggunakan backend Laravel lokal; integrasi Firebase lama telah dihapus. Pengembangan dan pengujian manual berfokus pada Android Emulator. Versi web belum tersedia.

## Arsitektur

```text
Flutter
  └── REST API Laravel (/api/v1)
        ├── PostgreSQL: akun, kategori, pendanaan, dan wishlist
        ├── Storage lokal: foto profil dan foto pendanaan
        └── Mailpit: email verifikasi dan reset password untuk pengembangan
```

Flutter berkomunikasi dengan Laravel melalui JSON dan multipart untuk unggahan gambar. Laravel menangani autentikasi, validasi, hak akses, serta penyimpanan data. File gambar disimpan pada storage backend, sementara database menyimpan referensi path gambar.

## Struktur project

```text
lib/
  core/                 Konfigurasi API, jaringan, dan komponen tampilan bersama
  features/
    auth/               Autentikasi, sesi, onboarding, dan navigasi utama
    profile/            Profil, keamanan akun, dan foto profil
    funding/            Pendanaan, kategori, pencarian, foto, dan wishlist
    health/             Pemeriksaan koneksi backend
  main.dart             Entrypoint aplikasi utama
  main_local.dart       Entrypoint diagnostik backend
backend/                REST API Laravel beserta pengujian backend
assets/images/          Logo dan aset gambar aplikasi
test/                   Pengujian Flutter
tool/                   Utilitas pemeriksaan koneksi backend
infra/                  Pendukung layanan lokal dan database pengujian
docs/                   Dokumentasi teknis dan catatan pengembangan
compose.yaml            Definisi layanan API, PostgreSQL, dan Mailpit
```