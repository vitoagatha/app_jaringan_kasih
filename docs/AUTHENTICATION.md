# Autentikasi P1

## Status

P1 selesai untuk lingkup autentikasi lokal Android. Migration telah dijalankan,
dan pengguna mengonfirmasi build serta pengujian manual emulator berhasil.
Review P1 dilakukan sebelum melanjutkan P2.

Verifikasi backend 25 Oktober 2026: `docker compose exec api php artisan test`
lulus 26 test dengan 124 assertion setelah perbaikan request tanpa Accept JSON. Pengujian
mencakup registrasi/hash, normalisasi/duplikasi email, validasi, login, bearer
token, kedaluwarsa, pencabutan token saat logout, dan pembatasan request.
Uji manual backend pada database belajar berhasil berdasarkan output pengguna.

Verifikasi Flutter: `flutter test --no-pub` lulus 40 test (26 autentikasi baru
dan 14 regresi P0). Analyzer pada main/main_local, core, features, test, dan tool
tidak menemukan masalah. Setelah penyesuaian AGP 8.6.1 dan Gradle 8.7, pengguna
melaporkan build Android, login, dan empat alur manual di bawah PASS.

Hasil manual pengguna: registrasi, `/me`, logout pertama, dan login berhasil.
Request berikutnya memakai token registrasi yang sudah dicabut dan menemukan bug
500 `Route [login] not defined` ketika header Accept JSON tidak dikirim. Callback
redirect guest diperbaiki pada bootstrap/app.php agar API menghasilkan 401 JSON.
Dua test regresi gagal sebelum perbaikan dan lulus setelahnya. Pengujian manual
ulang pengguna berhasil: `/me` mengembalikan akun, logout berhasil, dan pemakaian
ulang token yang dicabut menghasilkan 401. Server lokal tanpa token juga diuji 401.

Sanctum memakai token Bearer untuk aplikasi native. Guard cookie `web` tidak
dipakai pada API ini. Password database dan kredensial Firebase tidak dikirim ke
Flutter. Akun Firebase lama tidak otomatis menjadi akun backend lokal.

## Kontrak endpoint

Semua path di bawah berada pada `/api/v1/auth` dan memakai envelope ApiResponse.

| Metode/path | Input | Hasil |
| --- | --- | --- |
| POST `/register` | name, email, password, password_confirmation, device_name | 201: user, token, token_type, expires_at |
| POST `/login` | email, password, device_name | 200: user, token, token_type, expires_at |
| GET `/me` | Header Authorization: Bearer TOKEN | 200: user |
| POST `/logout` | Header Authorization: Bearer TOKEN | 200: data null; token saat ini dicabut |

`user` hanya berisi id, name, email, email_verified_at. Akun baru belum terverifikasi.
Email diubah ke huruf kecil dan spasi di awal/akhir dibuang. Password tidak di-trim;
registrasi minimal 8 karakter dan maksimal 72 byte sesuai batas bcrypt. Nama dan
device_name wajib teks maksimal 100 karakter; email maksimal 254 karakter.

Token disimpan sebagai hash di server. Nilai token asli hanya dikirim saat login
atau registrasi; respons diberi Cache-Control: no-store. Jangan menyertakan token
atau password dalam screenshot, log, commit, maupun laporan hasil test.

Token berlaku tujuh hari sejak diterbitkan, tanpa refresh token. Flutter
memvalidasi token tersimpan melalui `/me` saat aplikasi dibuka. Status 401 membuat
sesi lokal dibersihkan; gangguan jaringan harus menyediakan retry tanpa langsung
menghapus token. Setelah kedaluwarsa pengguna login kembali.

Logout mencabut token request saat ini; token login lain tetap berlaku. Setiap
login menerbitkan token baru. Daftar/revokasi semua perangkat belum tersedia.
Baris token kedaluwarsa dapat dipangkas kelak dengan perintah Sanctum; tidak ada
scheduler pembersihan yang dipasang pada tahap ini.

## Batas request

- Login: maksimal 5 request/menit untuk gabungan email yang dinormalisasi dan IP,
  serta 30 request/menit per IP untuk membatasi pergantian email.
- Registrasi: maksimal 5 request/menit per IP.
- Batas mencakup request valid maupun gagal; 429 membawa header Retry-After.
- Penyimpanan counter mengikuti cache Laravel (file pada lingkungan lokal).

## Langkah pengguna setelah kode siap

Dari root project, terapkan migration tambahan tanpa menghapus data:

```powershell
docker compose exec api php artisan migrate
docker compose exec api php artisan migrate:status
docker compose exec api php artisan route:list --path=api/v1/auth
docker compose exec api php artisan test
```

Test memakai database terpisah `jaringan_kasih_testing`. Tests/PostgresTestCase
memeriksa environment, driver, dan nama database sebenarnya sebelum RefreshDatabase
boleh menjalankan migration. Jangan menjalankan migrate:fresh pada database belajar.

## Integrasi Flutter

Pengguna memasang `flutter_secure_storage` 9.2.4. Token disimpan melalui adapter
SecureTokenStore; kuncinya mencakup alamat backend sehingga token backend berbeda
tidak tertukar. Mengganti API_BASE_URL memerlukan login pada alamat baru; token
untuk alamat lama tetap disimpan sampai logout pada alamat tersebut. Password
tidak disimpan. Android memakai encryptedSharedPreferences dan allowBackup=false
sesuai petunjuk package untuk menghindari restore data tanpa kunci enkripsi.

Entrypoint `lib/main.dart` menjalankan form dan gate sesi baru tanpa inisialisasi
Firebase. Setelah login, halaman akun menampilkan nama dan email dari server.
Pendanaan Laravel tersedia pada P4/P5. Pada P6, source/config/dependency Firebase
lama sudah dihapus. Pemeriksaan sesi background mempertahankan form pengguna yang
sama sambil memblokir interaksi; kegagalan/401 tetap mengikuti gate sesi.

Repository mengirim token Bearer dari memori dan menyimpannya setelah login atau
registrasi berhasil. Jika penyimpanan gagal, repository mengupayakan pencabutan
token baru dan menampilkan layar retry. Jika server tidak dapat dihubungi saat
pencabutan tersebut, token server tetap mengikuti expiry tujuh hari.

SessionController membatasi satu operasi aktif. Saat startup dan aplikasi kembali
aktif dari background, token tersimpan diperiksa melalui `/me`. Kegagalan jaringan
atau 5xx mengunci akses halaman akun dengan retry, tanpa menghapus token.
Respons 401 menghapus token dan membuka login. Logout hanya dinyatakan selesai
setelah token dicabut (atau sudah 401) dan penyimpanan lokal dibersihkan. Gangguan
jaringan saat logout mempertahankan akun dan menyediakan tombol Keluar untuk retry.
Kegagalan storage saat logout mengunci gate sesi sampai dapat diperiksa kembali.

Validasi Flutter membantu pengguna; backend tetap otoritas validasi. Pesan 422
ditampilkan di field terkait, dan 401/429/error jaringan ditampilkan sebagai pesan
yang dapat dicoba kembali. Selama submit, tombol dan field dinonaktifkan.

Target pengujian manual awal adalah Android Emulator pada Windows. Windows desktop
memakai API host 127.0.0.1, namun build/native storage Windows belum diverifikasi.
iOS/macOS/Linux belum diuji; macOS memerlukan konfigurasi Keychain Sharing dan izin
network client sebelum digunakan. Web belum didukung oleh ApiClient berbasis dart:io.
Test otomatis storage memakai mock platform sehingga tidak membuktikan enkripsi OS.
Pemulihan sesi setelah proses aplikasi ditutup sudah dilaporkan PASS oleh pengguna
pada emulator Android; platform lain dan ketahanan terhadap reinstall belum diuji.

## Hasil manual Flutter

| Pemeriksaan | Hasil dan bukti |
| --- | --- |
| Build dan login Android Emulator | PASS, dilaporkan pengguna setelah perbaikan AGP/Gradle |
| Tutup aplikasi sepenuhnya, buka lagi, sesi tetap masuk | PASS, konfirmasi pengguna nomor 1 |
| Logout, tutup/buka lagi, tetap di login | PASS, konfirmasi pengguna nomor 2 |
| Registrasi email lain dan identitas akun sesuai | PASS, konfirmasi pengguna nomor 3 |
| Password salah, email sudah terdaftar, konfirmasi berbeda | PASS, konfirmasi pengguna nomor 4 |
| Offline/retry dan logout saat jaringan terputus pada perangkat | NOT TESTED, belum ada konfirmasi manual |
| Kegagalan secure storage native | NOT TESTED, otomatis hanya memakai mock |

Keempat nomor konfirmasi pengguna merujuk pada daftar pengujian ringkas di chat;
urutan langkah panduan lengkap di bawah berbeda. Pengujian native dilaksanakan
pengguna, bukan diamati langsung oleh agen.

## Panduan mengulang pengujian manual

Hentikan aplikasi yang sedang berjalan dan jalankan ulang penuh setelah penambahan
plugin native; hot reload tidak cukup. Dari root project:

```powershell
docker compose up -d --wait
flutter run
```

Pada Android Emulator, API otomatis memakai `http://10.0.2.2:8000/api/v1/`.
Untuk HP fisik ikuti bind/LAN API_BASE_URL pada LOCAL_DEVELOPMENT.md.

1. Login dengan akun pengujian lokal yang sudah dibuat; nama/email harus sesuai server.
2. Tutup aplikasi sepenuhnya, lalu buka lagi pada perangkat yang sama: akun harus
   dipulihkan melalui `/me` tanpa mengisi password lagi.
3. Keluar: form login muncul. Tutup/buka lagi: harus tetap keluar.
4. Daftar memakai email lain: langsung masuk setelah registrasi; kemudian Keluar.
5. Coba password salah, konfirmasi tidak cocok, dan email sudah terdaftar: pesan
   harus tampil dan tidak membuka halaman akun.
6. Saat sudah login, matikan layanan API atau putus jaringan perangkat, kemudian
   buka ulang aplikasi: layar retry muncul. Nyalakan kembali dan Coba lagi; sesi
   harus dapat dipulihkan. Saat offline, logout tidak boleh mengklaim berhasil.

Profil, verifikasi email, reset/perubahan password mengikuti P2; upload gambar P3.
