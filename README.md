# Jaringan Kasih

Project belajar Flutter dengan Laravel REST API, PostgreSQL, storage lokal, dan Mailpit.

Status: P0 dan P1 selesai untuk lingkup lokal Android; build dan alur autentikasi
manual di emulator dilaporkan PASS oleh pengguna. P2/P3 dilanjutkan sesuai instruksi pengguna.
Entrypoint `lib/main.dart` menggunakan Laravel untuk registrasi, login, pemulihan sesi,
dan logout. `lib/main_local.dart` tetap tersedia untuk diagnostik backend.

P2/P3 sedang diimplementasikan: profil, email/password, dan foto profil. Instalasi
picker serta checklist perangkat mengikuti [panduan P2/P3](docs/ACCOUNT_AND_PHOTOS.md).

## Mulai lagi setelah komputer dinyalakan

Buka Docker Desktop dan tunggu engine siap. Dari root project:

```powershell
docker compose up -d --wait
docker compose ps
dart run tool/check_backend.dart http://127.0.0.1:8000/api/v1/
flutter run
```

Pilih Android Emulator saat Flutter meminta perangkat. Backend harus tetap berjalan.
Tidak perlu mengulang instalasi, key generation, atau migration setiap membuka project.

## Panduan

Untuk checkout baru, ikuti instalasi pertama pada panduan lokal, termasuk `flutter pub get`, sebelum menjalankan script Dart.

- [Setup lokal dan troubleshooting](docs/LOCAL_DEVELOPMENT.md)
- [Arsitektur dan kontrak API](docs/ARCHITECTURE.md)
- [Prioritas dan checklist P0](docs/ROADMAP.md)
- [Backend Laravel](backend/README.md)
- [Autentikasi P1 dan checklist manual](docs/AUTHENTICATION.md)
- [Profil, email/password, dan foto profil P2/P3](docs/ACCOUNT_AND_PHOTOS.md)

## Layanan lokal

| Layanan | Alamat dari komputer |
| --- | --- |
| Health API + PostgreSQL | http://127.0.0.1:8000/api/v1/health |
| Pemeriksaan proses Laravel | http://127.0.0.1:8000/up |
| Mailpit | http://127.0.0.1:8025 |
| PostgreSQL | 127.0.0.1:5433 |

Alamat API dari Android Emulator adalah `http://10.0.2.2:8000/api/v1/`.
HP fisik membutuhkan alamat IP komputer dan konfigurasi bind API; baca panduan lokal.

## Pengujian

```powershell
docker compose exec api php artisan test
flutter test --no-pub
```

Test database menggunakan `jaringan_kasih_testing`, terpisah dari `jaringan_kasih`.
Test mencakup fondasi P0, autentikasi P1, serta kode akun/foto P2/P3.
Pendanaan dan transaksi belum diimplementasikan pada backend lokal. Halaman lama yang memakai Firebase
masih disimpan dan belum dihubungkan ke alur aplikasi utama baru.
`.env`, password pribadi, token, dan APP_KEY tidak boleh dimasukkan ke Git.
