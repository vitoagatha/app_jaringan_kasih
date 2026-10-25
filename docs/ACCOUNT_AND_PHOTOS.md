# P2 dan P3: akun dan foto profil

## Status

Kode backend dan Flutter ditambahkan pada 25 Oktober 2026. image_picker sudah
terpasang dan tercatat pada lockfile; path public/storage tersedia. P2/P3 belum
ditutup: build Android, email nyata ke Mailpit, akses URL foto, serta alur manual
perangkat belum dikonfirmasi hasilnya.
Tidak ada migration baru: users sudah memiliki email_verified_at dan photo_path;
tabel password_reset_tokens juga sudah tersedia sejak P0.

## Menjalankan perubahan

Dari root project, pengguna menjalankan langkah berikut untuk belajar setup:

```powershell
flutter pub get
docker compose up -d --wait
docker compose exec api php artisan storage:link
flutter run
```

image_picker 1.1.2 sudah dideklarasikan pada pubspec.yaml; pub get memasang dependency
dan memperbarui lockfile. Perintah pub add yang diberikan sebelumnya juga dapat
dipakai jika belum dijalankan. Jika storage link sudah ada,
tidak perlu menghapus atau membuatnya ulang. Pemeriksaan awal menemukan link
public/storage belum tersedia. Konfigurasi mail yang terbaca: smtp, host mailpit,
port 1025. Bukti konfigurasi tidak berarti pengiriman email sudah diuji.

Jalankan ulang aplikasi sepenuhnya setelah memasang plugin native. Tidak perlu
mengubah Firebase, database, atau menjalankan migration tambahan untuk fitur ini.
Mailpit dibuka pada [localhost:8025](http://127.0.0.1:8025) dari komputer.
Mailpit menangkap email lokal; email tidak dikirim ke inbox internet.

## Kontrak API tambahan

Semua path di bawah relatif terhadap `/api/v1/auth`.

| Metode | Path | Input / perilaku |
| --- | --- | --- |
| PATCH | profile | name, email, current_password jika mengganti email |
| POST | change-password | current_password, password, password_confirmation |
| POST | forgot-password | email; respons generik untuk email terdaftar/tidak terdaftar |
| POST | reset-password | email, token, password, password_confirmation |
| POST | email/verification-notification | Bearer token; mengirim tautan verifikasi |
| GET | email/verify/{id}/{hash} | Tautan signed dari email, tanpa Bearer token |
| POST | profile/photo | Multipart field photo, Bearer token |
| DELETE | profile/photo | Bearer token; idempotent ketika foto sudah kosong |

Data user ditambah email_verified_at dan photo_url. photo_url bernilai null atau
path `/storage/avatars/...`, bukan path filesystem. Flutter menyelesaikannya dengan
origin API yang sedang dipakai dan menolak URL host lain atau path di luar avatars.

## Profil dan password

Edit profil mengubah nama dan email. Mengganti email membutuhkan password saat ini,
mereset status verifikasi, menghapus reset token email terkait, serta mencabut sesi
perangkat lain. Sesi perangkat yang mengubah email tetap aktif. Field internal,
password, status verifikasi, dan photo_path tidak dapat diubah lewat endpoint profil.

Password baru minimal delapan karakter dan maksimal 72 byte (batas bcrypt).
Password tidak di-trim. Perubahan password memerlukan password saat ini dan
konfirmasi yang sama; semua token perangkat serta reset token dihapus. Flutter
membersihkan secure storage dan kembali ke login setelah perubahan berhasil.

Lupa password memakai broker Laravel: token acak 64 karakter diemailkan, sementara
database menyimpan hash. Pengguna memasukkan token tersebut pada form aplikasi.
Token berlaku 60 menit, hanya sekali pakai, dan reset berhasil mencabut semua sesi.
Tidak dibutuhkan deep link atau Firebase untuk alur ini. Token/password tidak boleh
disertakan dalam screenshot/log yang dibagikan.

Login, reset, penggantian password/email diserialisasi menggunakan lock baris user
agar login bersamaan tidak menerbitkan sesi dari password yang sudah diganti.
Endpoint publik dibatasi 5 request/menit per email+IP serta 20/menit per IP;
broker reset juga membatasi pengiriman ulang per email selama 60 detik.

## Verifikasi email

Pengguna menekan Kirim verifikasi email setelah login. Pengiriman bersifat eksplisit;
registrasi tidak menunggu SMTP. Tautan bertanda tangan berlaku 60 menit dan mengikat
id serta hash email terkini. Tautan yang diubah, kedaluwarsa, atau berasal dari email
sebelum diganti ditolak. Pengiriman ulang dibatasi sekali per menit per user.

Tautan pada email memakai APP_URL backend. Untuk setup saat ini, buka email dan
tautannya pada komputer (APP_URL=127.0.0.1:8000), lalu pilih Periksa sesi di emulator.
Signature relatif tetap valid jika origin tautan disesuaikan ke host backend yang
dapat dijangkau perangkat. Tidak ada perubahan otomatis pada .env/APP_URL.
Login dan edit profil tidak diblokir oleh status belum terverifikasi; pembatasan
fitur pendanaan mengikuti kebutuhan P4.

## Foto profil

Galeri dan kamera memakai image_picker 1.1.2, dipilih untuk SDK Flutter yang ada.
Android menggunakan picker sistem, tanpa meminta akses seluruh penyimpanan.
Kamera memakai aplikasi kamera perangkat; perangkat tanpa kamera yang tersedia
menampilkan pesan gagal. Penolakan izin dan pembatalan tidak mengunggah file.
Deskripsi izin galeri/kamera iOS ditambahkan, tetapi build iOS belum diuji.

File dipilih dengan batas dimensi 4096 dan kualitas 85 jika didukung native picker.
Setelah pemrosesan native, client memeriksa panjang byte, signature JPEG/PNG/WebP,
dan metadata dimensi sebelum preview. Pemrosesan kualitas bukan jaminan file pasti
di bawah 2 MB: file terlalu besar tetap ditolak. HEIC/GIF/SVG tidak diterima kecuali
picker menghasilkan konversi ke format yang didukung.

Preview tidak otomatis diunggah. Tombol Unggah mengirim multipart binary dengan
nama field photo, MIME sesuai isi, filename yang dibuat client, serta token Bearer.
Backend kembali memvalidasi image/MIME, maksimal 2048 KB, dan ukuran setiap sisi
32–4096 piksel. Ekstensi asli saja tidak dipercaya. Batas PHP post/upload juga tetap
berlaku dan dapat menolak file sebelum validasi Laravel.

Backend menyimpan file bernama acak di disk public/avatars, lalu menyimpan path di
user. Bila transaksi database gagal, file baru dibuang. Setelah penggantian berhasil,
file lama dihapus; penghapusan foto mengosongkan path dan menghapus file terkait.
File public dapat diakses melalui URL tanpa autentikasi; disk lokal mengikuti
penyimpanan project, tanpa layanan cloud/billing.

Saat picker terbuka, pemeriksaan sesi pada event resumed ditunda agar preview tidak
hilang. Android retrieveLostData dijalankan saat editor foto dibuat setelah sesi
dipulihkan; hasilnya ditampilkan sebagai preview dan tetap menunggu konfirmasi upload.
Jika pemilihan tidak menghasilkan cached result, pengguna perlu memilih ulang.

## Pengujian

Backend memakai database testing terpisah dan Storage::fake; notifikasi memakai
Notification::fake. Test memeriksa kontrak notifikasi/signed URL tanpa mengirim SMTP.
Test Flutter memakai HTTP loopback, gateway, dan picker terkontrol; hasilnya tidak
membuktikan izin native, akses galeri/kamera, atau pemulihan aktivitas pada Android.
Hasil eksekusi terbaru dicatat pada ROADMAP.md setelah pengujian selesai.

Hasil eksekusi 25 Oktober 2026:

| Pemeriksaan | Hasil |
| --- | --- |
| Suite backend PostgreSQL | PASS: 40 test, 212 assertion |
| Suite Flutter tanpa pub get tambahan | PASS: 56 test; picker native memakai pengganti terkontrol |
| Analyzer main.dart, core, seluruh features (termasuk adapter picker), test | PASS: tidak ada masalah setelah dependency terpasang |
| Pint file PHP terkait | PASS |
| Konfigurasi SMTP | PASS: smtp/mailpit/1025 terbaca; bukan bukti pengiriman |
| Path public/storage | Tersedia saat pemeriksaan sebelum push; HTTP foto belum diuji |
| Build Android, permission native, gallery/camera | NOT TESTED pada perubahan P2/P3 |
| SMTP nyata ke Mailpit dan URL foto publik | NOT TESTED; pengujian backend memakai fake |

pubspec.yaml dan pubspec.lock sudah memuat image_picker 1.1.2. Pemeriksaan sebelum
push menjalankan analyzer termasuk entrypoint dan adapter DevicePhotoPicker;
hasilnya tidak membuktikan build atau operasi plugin di perangkat nyata.

## Checklist manual (belum dikonfirmasi)

1. Edit nama, simpan, buka ulang aplikasi: nama baru tetap ada.
2. Ganti email tanpa/password salah ditolak; dengan password benar berhasil dan
   status verifikasi menjadi belum terverifikasi.
3. Kirim verifikasi, buka Mailpit di komputer, klik tautan, lalu Periksa sesi di
   emulator: status menjadi terverifikasi. Ulangi kirim terlalu cepat: tampil 429.
4. Ubah password dengan password saat ini: kembali ke login, password lama ditolak,
   password baru berhasil. Sesi pada perangkat lain juga harus tidak valid.
5. Keluar, Lupa password, buka email Mailpit, masukkan token dan password baru.
   Token yang sama tidak boleh berhasil dipakai ulang.
6. Pilih foto galeri/kamera: preview tampil; Batal tidak mengubah foto server.
   Unggah, tutup/buka aplikasi: foto tetap tampil.
7. Ganti foto: foto baru tampil. Hapus: avatar kembali kosong, file lama terhapus.
8. Pilih format tidak didukung, gambar di atas 2 MB, atau tolak izin kamera/galeri:
   pesan harus tampil. Coba saat API dimatikan: tampil error dan dapat retry.
9. Android mematikan aktivitas saat picker terbuka: setelah kembali, periksa apakah
   cached result dipulihkan ke preview; unggah tetap perlu konfirmasi pengguna.

Pendanaan, transaksi, dan penghapusan seluruh kode Firebase lama tetap di luar P2/P3.
