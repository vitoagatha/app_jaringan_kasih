# Pendanaan dan wishlist P4/P5

## Status

Pengujian manual P2–P6 dilaporkan PASS oleh pengguna. Migration tabel pendanaan/
wishlist sudah Ran pada database belajar. Tambahan foto pendanaan sesudah konfirmasi
ini sudah diuji otomatis; migration kolom foto masih Pending dan manualnya belum diuji.

Tidak ada dependency baru. Autentikasi memakai sesi Laravel/Sanctum yang sama.
Setelah login, pilih Jelajahi pendanaan pada halaman akun. Tab yang tersedia:
Jelajahi, Milik saya, Wishlist. Data pendanaan berasal dari PostgreSQL.

## Aturan data dan akses

- Judul wajib, maksimal 150 karakter; deskripsi 20–10000 karakter.
- Kategori harus ada pada tabel categories; dropdown diisi melalui endpoint API.
- Target dana bilangan bulat rupiah, Rp1–Rp1.000.000.000.000.
- Draft hanya muncul pada daftar/detail pemilik; public detail draft mengembalikan 404.
- Published muncul pada daftar umum; penulis tetap satu-satunya pengguna yang bisa
  mengeditnya. Mengubah published menjadi draft menyembunyikannya dari daftar umum.
- user_id ditetapkan server dari token. Client tidak dapat mengubah pemilik,
  nominal terkumpul, atau timestamp melalui input pendanaan.
- Verifikasi email belum menjadi syarat menerbitkan pendanaan pada alur belajar lokal.
- Data publik pemilik hanya id dan nama; email/password tidak dikirim pada respons pendanaan.

Pendanaan terdiri dari judul, deskripsi, kategori, target, status, dan foto sampul opsional.
Pendanaan lama tanpa foto menampilkan placeholder dan dapat ditambahkan fotonya melalui Edit.
Pembayaran/ledger belum tersedia. raised_amount pada API selalu nol dan bukan hasil
perhitungan transaksi; UI tidak menampilkan tombol donasi atau progres donasi semu.
Draft/published menjadi mekanisme pengaturan visibilitas; penghapusan permanen
pendanaan bukan bagian alur saat ini.

Wishlist disimpan per user, memiliki unique constraint (user_id, funding_id), serta
foreign key. Menambahkan item berulang tidak membuat duplikasi. Penghapusan bersifat
idempotent dan hanya menghapus relasi pengguna aktif, termasuk ketika ID tidak ada.
Hanya pendanaan published yang bisa ditambahkan. Item yang menjadi draft disembunyikan
dari daftar wishlist; relasinya tetap ada sehingga muncul kembali jika diterbitkan lagi.

## Endpoint

Semua path relatif ke `/api/v1` dan memakai envelope ApiResponse.

| Metode | Path | Akses/peran |
| --- | --- | --- |
| GET | categories | Publik; items berisi id/name/slug |
| GET | fundings | Published; filter, search, pagination |
| GET | fundings/{id} | Detail published; draft selalu 404 |
| GET | me/fundings | Bearer; semua pendanaan milik pengguna |
| GET | me/fundings/{id} | Bearer pemilik; termasuk draft |
| POST | fundings | Bearer; membuat draft/published |
| PATCH | fundings/{id} | Bearer pemilik; field lengkap seperti create |
| GET | me/wishlist | Bearer; published yang disimpan pengguna |
| PUT | fundings/{id}/wishlist | Bearer; simpan published |
| DELETE | fundings/{id}/wishlist | Bearer; hapus relasi sendiri |

POST/PATCH menerima title, description, category_id, target_amount, status.
Mutasi menggunakan limiter account-write: 20 request/menit per pengguna bersama
mutasi akun. Pelanggaran pemilik saat edit menghasilkan 403; akses draft pengguna
lain pada own-detail menghasilkan 404. API dapat diakses publik untuk daftar/detail
published, sedangkan navigasi Flutter saat ini dimulai setelah login.

## Pencarian dan pagination

Query list mendukung page (minimal 1), per_page (1–30, default 10), search (judul,
maksimal 100 karakter), category_id. Daftar Milik saya juga mendukung status.
Search memakai ILIKE PostgreSQL dan tidak peka kapitalisasi. Karakter %, _ dan
backslash diperlakukan literal. Filter kategori dan pencarian dikombinasikan.

Urutan selalu created_at DESC, id DESC agar stabil ketika timestamp sama.
Respons data berisi items dan pagination: page, per_page, last_page, total.
Flutter memakai 10 item/halaman dan tombol Sebelumnya/Berikutnya. Pergantian tab,
filter atau pencarian dimulai dari halaman 1. Pencarian/filter kategori tetap
terlihat dan aktif saat tab berubah; filter status direset ketika berpindah tab.
Hasil kosong memiliki halaman terakhir 1; page di luar hasil menghasilkan items kosong.

Penerbitan/update langsung memengaruhi daftar umum. Draft baru tidak muncul pada
Jelajahi; buka Milik saya untuk mengaksesnya. Setelah simpan, Flutter membuka detail.
Tombol kembali Android dan app bar kembali dari editor → detail/daftar → akun.

## Migration oleh pengguna

Dari root project, ketika siap menerapkan struktur baru:

```powershell
docker compose up -d --wait
docker compose exec api php artisan migrate
docker compose exec api php artisan migrate:status
```

Migration tabel 2026_10_25_120000_create_fundings_and_wishlists_tables sudah Ran.
Tambahan 2026_10_25_130000_add_photo_path_to_fundings_table masih Pending;
menambah kolom nullable photo_path tanpa menghapus data lama.
Kategori tetap memakai enam data seed P0. Jika kategori belum terisi pada instalasi
baru, ikuti migrate --seed pada panduan setup lokal. Tidak ada seed pendanaan contoh.

Setelah migration, `flutter run` menggunakan entrypoint utama yang sama.
Migration database belajar dijalankan pengguna. Terapkan migration kolom foto
sebelum memakai versi baru endpoint pendanaan. Test otomatis memakai database terpisah
jaringan_kasih_testing dengan guard sebelum RefreshDatabase.

## Verifikasi otomatis

- Backend: 55 test lulus, 305 assertion (termasuk kasus foto pendanaan).
- Flutter: lihat hasil suite terbaru pada QUALITY_AND_CLEANUP.md.
- Analyzer main.dart, core, features, test: tidak ada masalah.
- Pint file PHP terkait: lulus.
- Database belajar: migration tabel Ran; migration kolom foto Pending.
- Manual P2–P6: PASS dilaporkan pengguna; tambahan foto pendanaan belum diuji manual.

Test backend mencakup kategori database, 401, kepemilikan, draft/publish, mass
assignment, filter/pagination/urutan, escape wildcard, wishlist per user/idempotensi,
serta constraint nominal SQL. Test Flutter memakai HTTP loopback/gateway terkendali:
kontrak URL/payload, token, parsing, navigasi akun, form, detail, wishlist, pagination,
dan retry. Test ini tidak menggantikan pengujian emulator end-to-end.

## Checklist manual P4/P5 (PASS dilaporkan pengguna)

1. Buat draft pada akun A; terlihat di Milik saya, tidak di Jelajahi.
2. Edit judul/target/kategori, lalu publish; terlihat di Jelajahi dan detail sesuai.
3. Login akun B; draft akun A tidak dapat dilihat dan pendanaan A tidak dapat diedit.
4. Simpan/hapus wishlist; buka ulang aplikasi dan periksa bahwa relasi tetap benar.
5. Pindah akun; wishlist akun A/B harus terpisah.
6. Buat lebih dari 10 published; periksa halaman berikut/sebelum, pencarian judul,
   filter kategori, dan urutan terbaru.
7. Jadikan item wishlist sebagai draft; item hilang dari daftar umum/wishlist.
8. Input invalid atau koneksi terputus: pesan tampil tanpa mengklaim simpan berhasil.

## Tambahan foto pendanaan

- Pilih galeri/kamera, preview, batalkan pilihan, ganti, dan hapus foto melalui editor.
  Perubahan foto baru diterapkan ketika Simpan ditekan.
- JPEG/PNG/WebP, maksimal 2 MB, dimensi setiap sisi 32–4096 piksel. Validasi client
  dan server memakai aturan yang sama dengan foto profil. SVG dan file palsu ditolak.
- Create dengan foto: POST multipart ke fundings. Edit dengan foto: POST multipart
  ke fundings/{id} dengan field _method=PATCH. Data lain tetap satu permintaan.
- Edit tanpa foto baru tetap PATCH JSON; remove_photo=true menghapus foto saat simpan.
  Server menolak unggah dan hapus bersamaan. Kepemilikan tetap diperiksa pada server.
- File diberi nama acak pada disk public, direktori fundings. API mengirim photo_url
  relatif /storage/fundings/...; Flutter memakai origin API aktif, termasuk 10.0.2.2
  pada emulator. Path lokal filesystem tidak dikirim ke client.
- Jika database gagal menyimpan, file baru dibersihkan; foto lama dihapus sesudah
  perubahan database berhasil. Test mencakup kegagalan create maupun penggantian.
- Cover ditampilkan pada Jelajahi, Milik saya, Wishlist, dan detail, dengan placeholder,
  status loading, dan tombol coba lagi ketika pemuatan gagal.
- Pemulihan picker Android dibatasi backend, pengguna, dan pendanaan. Foto pendanaan
  yang tertunda tidak boleh dipulihkan sebagai foto profil. Isi form selain foto tetap
  tidak dipersistenkan bila proses aplikasi ditutup.

Tidak ada dependency baru. public/storage harus tersedia seperti pada setup P3.
Setelah menjalankan migration di atas, buka ulang aplikasi untuk pengujian tambahan:

1. Buat pendanaan dengan foto; periksa cover pada daftar, detail, dan wishlist akun lain.
2. Edit/ganti foto; simpan, buka ulang, dan pastikan foto baru tetap tampil.
3. Hapus foto lalu simpan; placeholder tampil. Membatalkan pilihan tidak menghapus foto lama.
4. Tolak izin/batalkan picker dan coba file invalid; tidak ada pendanaan/foto baru yang tersimpan.

Checklist foto pendanaan ini masih NOT TESTED secara manual.
