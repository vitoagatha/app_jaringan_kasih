# Prioritas pengembangan

Tujuan: belajar Flutter dan backend Laravel secara lokal. Database PostgreSQL, storage disk lokal, email Mailpit.
Setup, instalasi, migrasi, dan Git/commit/push dijelaskan dahulu agar pengguna dapat menjalankannya sendiri.

| Tahap | Lingkup |
| --- | --- |
| P0 | Lingkungan lokal, Compose, koneksi PostgreSQL, kontrak API, migrations/seeder awal, client health Flutter, test, dokumentasi |
| P1 | Registrasi, login/logout Sanctum, validasi, token dan pemulihan sesi |
| P2 | Profil dasar, verifikasi email, reset dan perubahan password |
| P3 | Pilih/preview/validasi/upload gambar, foto profil, penggantian file |
| P4 | Daftar/detail/buat/edit pendanaan milik sendiri, kategori, draft/published |
| P5 | Wishlist per pengguna, pagination, filter, pencarian judul, urutan terbaru |
| P6 | Layout, aksesibilitas dasar, error/offline, pembersihan sisa Firebase, dokumentasi |

Transaksi/pembayaran, persetujuan admin, popularitas, deployment, dan distribusi rilis ditunda.

## Checklist penutupan P0

| Pemeriksaan | Bukti/status saat dokumentasi dibuat |
| --- | --- |
| Image API dan dependency container | Pengguna melaporkan berhasil |
| APP_KEY, PostgreSQL dan Mailpit | Pengguna melaporkan berhasil |
| Migration dan enam kategori | Terverifikasi dari output pengguna |
| HTTP health + query database | Pengguna melaporkan HTTP 200 setelah perbaikan no-reload |
| Client Dart ke backend nyata | Pengguna melaporkan PASS |
| Koneksi aplikasi lokal | Pengguna melaporkan sudah terhubung; bukti perangkat tidak direkam |
| Sintaks PHP | 25 file lulus pemeriksaan php -l |
| Suite backend Docker, termasuk PostgreSQL | Pengguna melaporkan 11 test lulus dengan 41 assertion |
| Widget test Flutter | Bug setState pada retry diperbaiki; ketiga widget test lulus, termasuk loading, retry, dan refresh |
| Suite Flutter lengkap | Setelah perbaikan review, 14 test lulus melalui flutter test --no-pub; empat test baru mencakup token/koneksi terlambat, close, dan POST bearer JSON |
| Dokumentasi | Setup awal/harian, troubleshooting, arsitektur, dan kontrak API tersedia |
| Auth dan fitur lainnya | Belum diimplementasikan |

P0 selesai diverifikasi pada 25 Oktober 2026 berdasarkan pemeriksaan lokal dan hasil eksekusi pengguna di atas.
Tahap berikutnya P1: registrasi, login/logout, Sanctum, token, dan pemulihan sesi.
Entrypoint aplikasi utama masih memakai Firebase lama; gunakan lib/main_local.dart untuk fondasi lokal sampai migrasi P1.

## Tindak lanjut review sebelum P1

- Timeout client: mencegah pengiriman setelah token/koneksi terlambat, menghentikan pembacaan respons, dan menolak request pada client yang ditutup; test regresi lulus.
- Script composer dev: memakai --no-reload, konsisten dengan Compose dan Dockerfile.
- Instalasi awal: mencantumkan flutter pub get sebelum script Dart/aplikasi.
- APP_URL untuk tautan email/gambar pada emulator/HP tetap dijadwalkan bersama P2/P3.
- Checkout bersih belum diuji; langkah instalasi didokumentasikan, bukan dinyatakan telah diuji ulang dari nol.
