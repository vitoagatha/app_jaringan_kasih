# P6: kualitas aplikasi dan pembersihan

## Status

Pengguna melaporkan pengujian manual P2–P6 PASS. Agen tidak mengulang uji perangkat
dan belum menjalankan screen reader atau build Android terpisah. Foto pendanaan
ditambahkan sesudah konfirmasi ini dan masih menunggu migration serta uji manual.
Ini bukan pernyataan siap rilis/deployment.

## Pembersihan Firebase dan dependency

Layar lama lib/screens, widget lama lib/widgets, lib/firebase_options.dart,
firebase.json, dan android/app/google-services.json dihapus karena tidak digunakan
oleh entrypoint Laravel. Konfigurasi plugin Google Services di settings.gradle dan
app/build.gradle dilepas. Sumber lama tetap dapat dipulihkan dari riwayat Git.
Tidak ada perubahan pada akun/layanan Firebase di luar project.

Dependency firebase_core, firebase_auth, cloud_firestore, carousel_slider,
icons_plus, dan cupertino_icons dihapus dari manifest. Lockfile serta metadata
package/registrasi plugin telah diperbarui melalui pub get; pemeriksaan source,
konfigurasi native, dan lockfile tidak menemukan referensi Firebase aktif.
Registrasi plugin hasil generate tidak diedit manual.

Deklarasi bundle aset gambar lama dihapus agar gambar yang tidak dipakai UI tidak
ikut dibundel. File aslinya tetap disimpan pada assets/images untuk fixture test
dan contoh gambar emulator; ikon launcher native tetap tersedia.

Dependency Flutter aktif: flutter SDK, intl, flutter_secure_storage, image_picker;
dev dependency flutter_test dan flutter_lints. Tidak ada package konektivitas baru.

## Layout dan aksesibilitas dasar

- AppContent memberi SafeArea dan batas lebar baca 840 piksel; form pendanaan 720.
  Form autentikasi tetap memakai batas 440 piksel.
- Tema Material 3 memakai target sentuh minimum 48 piksel untuk tombol.
- Dropdown kategori/status memakai ellipsis untuk label panjang; nilai lengkap
  tetap tersedia pada teks/semantik. Label target rupiah dipersingkat dan diberi helper.
- Pagination memakai Wrap sehingga tombol dapat turun baris pada layar sempit/teks besar.
- Panel kegagalan sesi dapat di-scroll, mempunyai live region, pesan, dan retry.
- Foto diberi label semantik untuk membedakan avatar sekarang dan preview.
  Kegagalan memuat foto menyediakan tombol Muat ulang foto.
- Indikator proses mempunyai label semantik. Halaman/form tetap dapat digulir.

Test menguji layar 320 piksel, text scale 1.8/2, form desktop 1600 piksel, serta
androidTapTargetGuideline dan labeledTapTargetGuideline pada form login. Ini bukan
sertifikasi aksesibilitas seluruh aplikasi. TalkBack/VoiceOver/keyboard desktop
belum diuji secara manual.

## Sesi saat kembali dari background

Startup masih memeriksa token sebelum membuka akun. Pada event resumed,
restore(keepView: true) mempertahankan halaman/form pengguna yang sama, menampilkan
indikator proses, dan memblokir interaksi sementara. Draft di memori tidak hilang
hanya karena pemeriksaan sesi. Jika id user berubah, KeyedSubtree mengganti state
halaman sehingga form/data user sebelumnya tidak dipakai ulang.

Respons 401 tetap membersihkan sesi dan membuka login. Gangguan jaringan mengarah
ke panel retry; token tidak otomatis dihapus. Pemilihan gambar tetap memakai guard
externalInteraction agar proses picker tidak menghilangkan preview.

Form yang belum disimpan tidak dipersistenkan ke disk. Menutup proses aplikasi
sepenuhnya masih menghapus isi form tersebut. Token login tetap ditangani secure storage.

## Error/offline

ApiClient mempertahankan status HTTP walaupun respons error berupa HTML/non-JSON.
Detail mentah upstream tidak ditampilkan. Respons 200 yang tidak sesuai kontrak
tetap dianggap error format. Kesalahan TLS ditampilkan sebagai pesan koneksi aman;
validasi sertifikat tidak dinonaktifkan.

429 membaca Retry-After berupa jumlah detik atau tanggal HTTP. Metadata yang tidak
valid diabaikan tanpa menutupi status 429. displayMessage memberi petunjuk waktu
tunggu pada UI. Tidak ada retry otomatis pada POST/PATCH/upload; pengguna memilih
sendiri kapan mencoba kembali. Ini mencegah pengiriman ulang mutasi tanpa kepastian.

Tidak ada cache data pendanaan offline atau detektor konektivitas terpisah. Status
berasal dari hasil request sebenarnya; timeout/socket/HTTP ditampilkan melalui
pesan dan retry. Jaminan timeout P0 dan isolasi token per alamat backend tetap berlaku.

## Platform

Entrypoint main.dart dan main_local.dart memeriksa kIsWeb sebelum mengakses Platform
atau membuat HTTP client native. Browser menampilkan layar penjelasan platform yang
didukung. Ini fallback UI, bukan dukungan API web. Build/runtime browser belum diuji
langsung setelah perubahan ini.

Android tetap target utama. Windows memerlukan toolchain desktop yang sesuai.
Persyaratan iOS/macOS/Linux mengikuti panduan P2/P3 dan belum diverifikasi di host ini.

## Hasil verifikasi

| Pemeriksaan | Hasil |
| --- | --- |
| Suite Flutter | PASS: 95 test sesudah tambahan foto pendanaan |
| flutter analyze --no-pub seluruh project | PASS: tidak ada masalah |
| Layout sempit, teks besar, lebar form desktop | PASS pada widget test |
| Dua guideline aksesibilitas form login | PASS pada widget test |
| Draft saat pemeriksaan sesi background | PASS pada controller/widget test |
| Error non-JSON 401/503, Retry-After valid/tidak valid, TLS | PASS pada test transport |
| Pencarian referensi Firebase aktif | Tidak ditemukan pada source/native config/lockfile |
| Build Android setelah dependency dibersihkan | NOT TESTED |
| Manual P2–P6 | PASS dilaporkan pengguna; tidak diulang agen |
| Manual tambahan foto pendanaan | NOT TESTED; migration kolom foto masih Pending |

Suite backend sesudah tambahan foto: 55 test lulus, 305 assertion. Migration P4
fundings/wishlists sudah Ran; migration kolom foto masih Pending. Tidak ada migration
baru dari P6; kolom foto merupakan tambahan P4.

## Menjalankan setelah pembersihan

Pada checkout baru atau setelah manifest dependency berubah, pengguna menjalankan:

```powershell
flutter pub get
docker compose up -d --wait
```

Untuk menerapkan migration tambahan yang masih pending:

```powershell
docker compose exec api php artisan migrate
docker compose exec api php artisan migrate:status
```

Untuk build/run Android berikutnya, hentikan proses Flutter lama dan jalankan ulang
`flutter run` penuh. Hot reload tidak cukup setelah plugin native dilepas.
Tidak perlu mereset database, emulator, atau menghapus cache Gradle global.

Panduan fitur: AUTHENTICATION.md, ACCOUNT_AND_PHOTOS.md, FUNDING_AND_WISHLIST.md.
Transaksi/pembayaran, approval, deployment, dan rilis tetap di tahap akhir.
