# Jaringan Kasih

Project belajar Flutter dengan Laravel REST API, PostgreSQL, storage lokal, dan Mailpit.

Status: fondasi P0 tersedia; migrasi autentikasi dan fitur dari Firebase dilakukan bertahap mulai P1.
Entrypoint `lib/main.dart` masih memakai Firebase lama. Jalankan `lib/main_local.dart` untuk memeriksa backend lokal.

## Mulai lagi setelah komputer dinyalakan

Buka Docker Desktop dan tunggu engine siap. Dari root project:

```powershell
docker compose up -d --wait
docker compose ps
dart run tool/check_backend.dart http://127.0.0.1:8000/api/v1/
flutter run -t lib/main_local.dart
```

Pilih Android Emulator saat Flutter meminta perangkat. Backend harus tetap berjalan.
Tidak perlu mengulang instalasi, key generation, atau migration setiap membuka project.

## Panduan

Untuk checkout baru, ikuti instalasi pertama pada panduan lokal, termasuk `flutter pub get`, sebelum menjalankan script Dart.

- [Setup lokal dan troubleshooting](docs/LOCAL_DEVELOPMENT.md)
- [Arsitektur dan kontrak API](docs/ARCHITECTURE.md)
- [Prioritas dan checklist P0](docs/ROADMAP.md)
- [Backend Laravel](backend/README.md)

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
Test P0 belum mencakup fitur registrasi, login, upload gambar, pendanaan, atau transaksi.
`.env`, password pribadi, token, dan APP_KEY tidak boleh dimasukkan ke Git.
