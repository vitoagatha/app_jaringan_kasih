# Prioritas pengembangan

Tujuan: belajar Flutter dan backend Laravel secara lokal. Database PostgreSQL, storage disk lokal, email Mailpit.
Setup, instalasi, migrasi, dan Git/commit/push dijelaskan dahulu agar pengguna dapat menjalankannya sendiri.

Status terbaru 25 Oktober 2026: pengguna melaporkan manual P2–P6 PASS. Catatan progres
di bawah merekam hasil saat tiap tahap dibuat. Tambahan foto pendanaan sesudah
konfirmasi ini diuji otomatis dan menunggu migration serta manual baru;
lihat [FUNDING_AND_WISHLIST.md](FUNDING_AND_WISHLIST.md).

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
Entrypoint diagnostik P0 adalah lib/main_local.dart. P1 mengganti lib/main.dart
dengan autentikasi Laravel; halaman fitur Firebase lama kemudian dihapus pada P6.

## Progres P1

Sanctum 4.3.3 sudah dipasang pengguna. Kode endpoint register/login/me/logout,
validasi, pembatasan request, masa berlaku token tujuh hari, serta test backend
ditambahkan. Status verifikasi dan cara pemakaian mengikuti
[AUTHENTICATION.md](AUTHENTICATION.md). Integrasi Flutter mencakup repository,
secure storage, gate/controller sesi, form registrasi/login, akun aktif, dan logout.
Suite Flutter lulus 40 test (26 test autentikasi baru dan 14 regresi P0).
Backend lulus 26 test dengan 124 assertion; analyzer kode P0/P1 tidak menemukan masalah.
Pengguna melaporkan build Android dan empat alur manual PASS: pemulihan sesi setelah
aplikasi ditutup, logout yang bertahan setelah buka ulang, registrasi, dan validasi
(password salah, email terdaftar, konfirmasi berbeda).
P1 selesai untuk lingkup autentikasi lokal Android berdasarkan bukti tersebut.
Uji manual offline/gangguan storage dan platform selain Android belum dikonfirmasi;
kasus kegagalan terkait tercakup dalam test otomatis dengan server/gateway/storage terkontrol.
Pengguna selanjutnya meminta implementasi P2/P3 langsung.
Profil, email, dan password reset tetap P2.

## Progres P2/P3

Backend dan Flutter untuk profil, verifikasi email, reset/perubahan password, serta
foto profil sedang ditambahkan. Tidak ada migration baru. Instalasi image_picker
dan pembuatan storage link dijalankan pengguna. Detail kontrak, batasan platform,
dan checklist manual: [ACCOUNT_AND_PHOTOS.md](ACCOUNT_AND_PHOTOS.md).
Hasil otomatis: backend 40 test lulus (212 assertion), Flutter 56 test lulus;
analyzer main.dart/core/features/test (termasuk adapter picker) lulus setelah
image_picker terpasang dan lockfile diperbarui. SMTP/foto publik/native runtime
belum dikonfirmasi hasil manualnya. Konfigurasi SMTP terbaca smtp/mailpit/1025;
path public/storage tersedia pada pemeriksaan sebelum push.
P2/P3 belum ditutup sebelum dependency/native build dan pengujian perangkat dikonfirmasi.

## Progres P4/P5

Pengguna meminta menunda pengujian manual P2/P3 dan melanjutkan implementasi P4/P5.
Kode kategori/pendanaan pemilik, draft/published, wishlist per user, pencarian judul,
filter, pagination, dan urutan terbaru tersedia pada backend dan Flutter.
Backend: 48 test lulus (262 assertion); Flutter: 70 test lulus; analyzer terkait bersih.
Migration baru untuk fundings/wishlists belum diterapkan pada database belajar;
test memakai database testing terpisah. Pengujian emulator P4/P5 belum dilakukan.
Detail kontrak dan langkah migration: [FUNDING_AND_WISHLIST.md](FUNDING_AND_WISHLIST.md).
P2/P3 dan P4/P5 tetap menunggu verifikasi manual; transaksi/pembayaran tetap ditunda.

## Progres P6

Kode P6 tersedia: layout responsif, aksesibilitas dasar, retry foto, error/offline,
Retry-After, perlindungan form saat revalidasi sesi background, dan fallback browser.
Source/config/dependency Firebase serta library lama yang tidak dipakai dibersihkan;
lockfile/registrasi plugin sudah diperbarui. Flutter lulus 84 test; analyzer seluruh
project bersih. Rincian: [QUALITY_AND_CLEANUP.md](QUALITY_AND_CLEANUP.md).
Build Android pasca-cleanup dan pengujian manual P2–P6 belum dikonfirmasi.
P6 tidak membuat migration baru; migration P4 pada database belajar masih Pending.

## Catatan review fondasi P0 (historis)

- Timeout client: mencegah pengiriman setelah token/koneksi terlambat, menghentikan pembacaan respons, dan menolak request pada client yang ditutup; test regresi lulus.
- Script composer dev: memakai --no-reload, konsisten dengan Compose dan Dockerfile.
- Instalasi awal: mencantumkan flutter pub get sebelum script Dart/aplikasi.
- APP_URL untuk tautan email/gambar pada emulator/HP tetap dijadwalkan bersama P2/P3.
- Checkout bersih belum diuji; langkah instalasi didokumentasikan, bukan dinyatakan telah diuji ulang dari nol.
