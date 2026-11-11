# Aktivitas admin dan status akun pengguna

Tahap ini menambahkan pengelolaan akses akun pengguna dan riwayat tindakan admin. Modul persetujuan pendanaan, donasi, dan transaksi tetap ditunda.

## Aktivasi

Dari root project, setelah layanan Docker berjalan:

```powershell
docker compose exec api php artisan migrate
```

Migration `2026_11_11_000001_add_account_status_and_admin_activity_logs` menambahkan status akun dan tabel aktivitas. Akun yang sudah ada tetap aktif. Tidak ada backfill aktivitas lama, perubahan role, atau perubahan status pendanaan. Aktifkan migration sebelum menggunakan kode backend baru.

Gunakan akun admin yang sudah dibuat. Jika belum memiliki akun admin, ikuti [panduan dashboard](ADMIN_DASHBOARD.md). Jalankan ulang aplikasi Flutter setelah backend diperbarui.

## Pengelolaan status

Menu **Pengguna** memiliki label dan filter Aktif/Nonaktif. Detail pengguna menampilkan status, pelaksana, waktu, serta alasan perubahan terakhir.

Admin dapat menonaktifkan atau mengaktifkan kembali akun pengguna biasa melalui detail akun. Kedua tindakan wajib disertai alasan maksimal 1.000 karakter dan konfirmasi UI. Akun admin, termasuk akun sendiri, tidak dapat menjadi sasaran tindakan ini. Constraint PostgreSQL juga mencegah role admin memiliki status nonaktif.

Backend mengunci baris pengguna, memeriksa `status_version`, lalu menyimpan perubahan dan aktivitas dalam satu transaksi. Pengiriman ulang atau form lama ditolak; admin perlu memuat ulang halaman. Jika pencatatan aktivitas gagal, perubahan status dan pencabutan token ikut dibatalkan.

Registrasi publik dan pembaruan profil aplikasi tidak dapat mengubah `is_active`, role, alasan, pelaksana, atau versi status. Reset password tidak mengaktifkan kembali akun nonaktif.

## Token dan aplikasi Flutter

- Saat akun dinonaktifkan, seluruh token aktif dibuat kedaluwarsa melalui `expires_at`. Token sudah tidak berlaku, meskipun baris hash-nya masih disimpan untuk mengenali akun yang dinonaktifkan.
- Middleware memeriksa status sebelum autentikasi Sanctum pada seluruh route API terlindungi. Pemilik token akun nonaktif menerima HTTP 403 dengan `code: account_disabled`. Login juga menolak akun nonaktif setelah password yang diberikan terbukti benar.
- Alasan internal admin tidak dikirim ke aplikasi. Pesan pengguna: **Akun Anda dinonaktifkan. Hubungi pengelola untuk bantuan.**
- Client Flutter menghapus token dan menutup sesi untuk respons tersebut dari fitur mana pun. HTTP 401 juga membatalkan sesi; HTTP 403 biasa tanpa kode penonaktifan tidak menyebabkan logout.
- Respons terlambat yang memakai token lama tidak boleh menghapus token dari login yang lebih baru. Jika penghapusan secure storage gagal, layar akun dikunci sampai penyimpanan dapat diperiksa kembali.
- Setelah pengaktifan kembali, token lama tetap kedaluwarsa. Pengguna harus login ulang untuk memperoleh token baru.
- Jika token telah dipangkas atau dihapus oleh alur reset password, request lama dapat menerima HTTP 401 biasa. Login dengan kredensial yang benar tetap mengembalikan pesan penonaktifan selama akun nonaktif.

Tidak ada push atau polling status akun. Flutter mengetahui penonaktifan ketika menerima respons API terlindungi atau memeriksa ulang sesi saat kembali dari background. Akses ke data publik tetap mengikuti hak akses anonim; penonaktifan tidak menghapus profil, pendanaan, atau wishlist, dan tidak mengubah penayangan pendanaan yang sudah published.

## Riwayat aktivitas

Menu **Aktivitas admin** mencatat:

| Tindakan | Data perubahan |
| --- | --- |
| Pengguna dinonaktifkan/diaktifkan | Status sebelum/sesudah dan alasan |
| Kategori ditambahkan/diperbarui/dihapus | Nama dan slug sebelum/sesudah |
| Profil admin diperbarui | Kolom nama/email yang benar-benar berubah |
| Password admin diubah | Kejadian dan waktu saja |

Setiap catatan menyimpan identitas/nama admin saat tindakan, jenis objek, ID/label objek, waktu, serta snapshot perubahan. Snapshot tetap tersedia setelah kategori dihapus atau nama objek berubah. Password, hash, token, dan remember token tidak direkam; pencatat memakai daftar kolom yang diizinkan.

Perubahan kategori, profil, password, dan status dicatat dalam transaksi database yang sama dengan tindakannya. Validasi gagal dan penyimpanan tanpa perubahan tidak membuat aktivitas palsu. Pengiriman email verifikasi dan login/logout bukan bagian dari jenis aktivitas pada tahap ini.

Daftar aktivitas mendukung filter admin, tindakan, rentang tanggal, objek dari tautan detail pengguna, serta pagination 20 data. Detail menampilkan perbandingan sebelum/sesudah. Waktu mengikuti timezone aplikasi yang ditampilkan pada halaman. Tidak ada route edit/hapus aktivitas; model aplikasi juga menolak pembaruan dan penghapusan catatan.

## Pengujian

Pengujian backend memakai `jaringan_kasih_testing` melalui pemeriksaan keselamatan `PostgresTestCase`. Database aplikasi tidak dipakai untuk migration pengujian.

```powershell
docker compose exec api php artisan test
flutter test --no-pub
flutter analyze --no-pub
```

Pengujian mencakup hak akses, alasan wajib, perlindungan admin, form kedaluwarsa, rollback saat audit gagal, token lama pada seluruh API terlindungi, pengaktifan kembali, reset password tanpa aktivasi, pencatatan perubahan tanpa rahasia, filter/pagination, serta escaping data pada tampilan.

Pengujian Flutter mencakup respons penonaktifan dari request pendanaan, pemulihan sesi, HTTP 401 non-JSON, HTTP 403 biasa, kegagalan secure storage, respons sesi lama, dan perpindahan layar ke login dengan pesan penonaktifan.

Hasil verifikasi pada 11 November 2026:

| Pemeriksaan | Hasil |
| --- | --- |
| Seluruh suite backend, termasuk 15 pengujian baru | PASS: 90 test, 596 assertion |
| Seluruh suite Flutter, termasuk 8 pengujian baru | PASS: 108 test |
| `flutter analyze --no-pub` | PASS: tidak ada masalah |
| Sintaks PHP dan format Laravel Pint | PASS pada file terkait |
| Halaman aktivitas/detail/status pada browser desktop | PASS pada preview Blade dengan data testing |
| Halaman aktivitas pada lebar 375 px | PASS: tidak ada overflow halaman horizontal; tabel memiliki area gulir sendiri |
| Alasan wajib dan dialog konfirmasi status | PASS pada preview browser; perubahan status tidak disubmit |
| Migration pada database aplikasi dan uji manual dashboard–Flutter | Belum dijalankan; migration berstatus Pending |

Pengujian UI profil/foto dan navigasi pendanaan yang lama disesuaikan agar membuka tab Akun terlebih dahulu dan menggulir ke pesan hasil tindakan. Pemeriksaan fungsional sebelumnya tetap dipertahankan. Preview browser memakai data contoh dalam transaksi testing yang di-rollback; server preview sementara dihentikan setelah pemeriksaan.

Setelah migration pada database aplikasi, periksa manual dengan akun pengguna percobaan: login Flutter, nonaktifkan melalui dashboard, lakukan request terlindungi/kembali dari background, pastikan sesi ditutup, lalu aktifkan kembali dan login ulang. Riwayat harus memuat kedua tindakan beserta alasan dan pelaksana yang sesuai.
