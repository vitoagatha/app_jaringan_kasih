# Dashboard admin Jaringan Kasih

Panel web lokal memakai Laravel Blade dan Tabler 1.7.4. Panel berbagi PostgreSQL dengan aplikasi Flutter, tetapi memakai autentikasi sesi web. Aplikasi Flutter tetap memakai bearer token Sanctum.

## Lingkup tahap ini

- Ringkasan jumlah pengguna aplikasi, email terverifikasi/belum terverifikasi, kategori, pengguna terbaru, dan pendaftaran tujuh hari terakhir.
- Daftar pengguna dengan pencarian, filter role/verifikasi/status, pagination, detail akun, dan pengelolaan status aktif/nonaktif pengguna biasa.
- Aktivitas admin: riwayat tindakan, snapshot perubahan, filter admin/tindakan/tanggal, dan detail yang hanya dapat dibaca.
- Kategori: pencarian, tambah, edit, dan hapus. Kategori yang masih dipakai pendanaan tidak dapat dihapus.
- Profil admin: nama/email, pengiriman verifikasi email, dan perubahan password.
- Sidebar responsif, login/logout, CSRF, pembatasan percobaan login, dan pemeriksaan role pada setiap route terlindungi.

Statistik ringkasan menghitung akun dengan role `user`; daftar pengguna juga dapat menampilkan admin melalui filter role. Semua angka berasal dari database. Tidak ada pengelolaan pendanaan, persetujuan, donasi, atau transaksi pada panel tahap ini. Rincian tahap lanjutan tersedia pada [aktivitas admin dan status akun](ADMIN_ACTIVITY_AND_ACCOUNT_STATUS.md).

## Aktivasi oleh pengembang

Jalankan perintah berikut dari root project setelah Docker Desktop siap:

```powershell
docker compose up -d --wait
docker compose exec api php artisan migrate
docker compose exec api php artisan admin:create
```

Migration baru menambahkan kolom `role` dan constraint `user/admin`. Akun lama otomatis memiliki role `user`; tidak ada pengguna yang otomatis menjadi admin. Migration ini tidak mengubah status pendanaan.

Perintah `admin:create` meminta email baru, nama, password, dan konfirmasi password. Password disembunyikan saat diketik dan disimpan sebagai hash. Perintah menolak email yang sudah terdaftar, sehingga tidak mengubah atau menaikkan role akun lama. Tidak ada akun/password admin bawaan dan tidak ada seeder admin.

Buka **http://127.0.0.1:8000/admin/login**, lalu gunakan akun admin yang Anda buat. Akses `/admin` tanpa sesi web diarahkan ke halaman login. Akun aplikasi biasa tidak dapat masuk melalui form admin; akses langsungnya ke route admin ditolak.

## Hak akses dan sesi

- Kolom `role` tidak termasuk atribut mass assignment pengguna. Registrasi publik tidak dapat meminta role admin.
- Panel tidak menyediakan tombol/form untuk menaikkan role, mengedit nama/email/password pengguna lain, atau memverifikasi email orang lain. Admin hanya dapat mengubah status akses pengguna biasa dengan alasan wajib dan catatan aktivitas.
- Pembaruan profil hanya menyimpan nama/email admin yang sedang masuk. Mengganti email memerlukan password saat ini dan menghapus status verifikasi email lama.
- Pengiriman tautan verifikasi memakai alur email yang sudah tersedia. Pada lingkungan lokal email masuk ke Mailpit.
- Perubahan password membutuhkan password lama, konfirmasi, minimal 8 karakter, dan maksimal 72 byte. Token aplikasi dicabut; middleware `auth.session` menolak sesi web lain yang masih menyimpan hash password lama. Browser yang melakukan perubahan tetap masuk.
- Logout membatalkan sesi browser, bukan seluruh token aplikasi pada perangkat lain.
- Semua form perubahan data memakai CSRF. Informasi halaman admin diberi header `Cache-Control: no-store, private`.
- Penghapusan kategori memerlukan konfirmasi di UI dan diperiksa ulang pada backend. Constraint foreign key PostgreSQL tetap menjadi perlindungan saat ada request bersamaan.

## Template dan aset

Tabler berlisensi MIT. CSS, JavaScript, dan lisensinya disimpan pada `backend/public/vendor/tabler/`. Logo disalin dari `assets/images/icon_splash.png` ke `backend/public/images/jaringan-kasih.png`. CSS/JS aplikasi berada pada `backend/public/css/admin.css` dan `backend/public/js/admin.js`.

Dashboard tidak memerlukan CDN saat digunakan atau build frontend Vite. Tidak ada paket Composer/NPM baru yang dipasang untuk panel ini. Sumber upstream tercantum pada README folder vendor Tabler.

## Struktur kode

| Lokasi | Peran |
| --- | --- |
| `backend/routes/admin.php` | Route panel web, dipanggil dari `routes/web.php` |
| `backend/app/Http/Controllers/Admin/` | Login, ringkasan, pengguna, kategori, dan profil |
| `backend/app/Http/Middleware/EnsureAdmin.php` | Pemeriksaan role setiap request admin |
| `backend/app/Console/Commands/CreateAdmin.php` | Pembuatan akun admin interaktif |
| `backend/resources/views/admin/` | Layout dan halaman Blade |
| `backend/resources/views/components/admin/` | Komponen ikon SVG |
| `backend/tests/Feature/AdminDashboardTest.php` | Pengujian autentikasi, otorisasi, data, dan form admin |

## Verifikasi

```powershell
docker compose exec api php artisan test --filter=AdminDashboardTest
docker compose exec api php artisan test
```

Pengujian memakai `PostgresTestCase` dengan pemeriksaan nama database `jaringan_kasih_testing` sebelum migration pengujian. Perintah test tidak menerapkan migration ke database pengembangan `jaringan_kasih`.

Hasil pemeriksaan pada 10 November 2026:

| Pemeriksaan | Hasil |
| --- | --- |
| Seluruh suite backend, termasuk 20 pengujian admin | PASS: 75 test, 452 assertion |
| Sintaks file PHP baru | PASS |
| Format PHP menggunakan Laravel Pint | PASS |
| Login web dan pemuatan aset lokal | PASS pada browser lokal |
| Tampilan ringkasan desktop dan layar 375 px | PASS pada preview dengan data testing; tidak ada overflow halaman horizontal |
| Buka/tutup navigasi mobile dan dialog konfirmasi kategori | PASS pada preview browser; penghapusan tidak disubmit |
| Halaman pengguna, kategori, profil, dan kondisi kosong | PASS pada pengujian render backend |
| Migration role dan pembuatan admin pada database aplikasi | Belum dijalankan; dilakukan pengembang melalui langkah aktivasi di atas |
| Alur manual lengkap dengan akun admin milik pengembang | Belum diuji; menunggu aktivasi |

Preview visual memakai halaman Blade yang dirender dengan data contoh dalam transaksi pada database testing, kemudian di-rollback. Angka dan akun pada screenshot preview bukan data pengguna aplikasi. Server preview sementara dihentikan setelah pemeriksaan.

Setelah aktivasi, periksa manual: login admin dan penolakan akun biasa, menu ringkasan/pengguna/kategori/profil, pencarian/pagination, validasi kategori duplikat, larangan hapus kategori terpakai, perubahan profil/password, logout, dan navigasi layar kecil.
