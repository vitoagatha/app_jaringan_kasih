# Menjalankan Jaringan Kasih lokal

Semua perintah di bawah dijalankan dari root repository melalui PowerShell.
Gunakan langkah manual untuk belajar; `scripts/Start-Local.ps1` tersedia sebagai otomatisasi setelah memahami urutannya.

## Kebutuhan

- Docker Desktop dengan Linux engine/WSL2 aktif dan Docker Compose v2.
- Flutter dan Dart yang kompatibel dengan `pubspec.yaml` (environment awal: Flutter 3.27.3 / Dart 3.6.1).
- Android Emulator atau HP pengujian.
- Internet saat mengunduh image/dependency pertama kali.

Backend berjalan dengan PHP dan ekstensi PostgreSQL di dalam container, sehingga PHP host tidak wajib diubah.
Laravel 12 dipilih agar tetap kompatibel dengan PHP 8.2 yang tersedia pada lingkungan awal.

## Instalasi pertama

1. Pasang dependency Flutter sekali dari root project (atau setelah dependency berubah):

```powershell
flutter pub get
```

Langkah ini membuat konfigurasi package yang diperlukan oleh import `package:` pada script Dart dan aplikasi.
`flutter test --no-pub` pada langkah berikutnya mengasumsikan dependency tersebut sudah tersedia.

2. Buka Docker Desktop dan pastikan `docker version` menampilkan Client dan Server.
3. Jika belum ada `.env`, salin contoh sekali:

```powershell
if (-not (Test-Path -LiteralPath 'backend/.env')) {
    Copy-Item -LiteralPath 'backend/.env.example' -Destination 'backend/.env'
}
docker compose config --quiet
docker compose build api
docker compose run --rm --no-deps api composer install --no-interaction --prefer-dist
```

4. Periksa APP_KEY tanpa menampilkan rahasianya:

```powershell
Select-String -LiteralPath 'backend/.env' -Pattern '^APP_KEY=base64:.+' -Quiet
```

Jika hasilnya `False`, buat satu kali:

```powershell
docker compose run --rm --no-deps api php artisan key:generate
```

5. Jalankan database/email, lalu migration dan kategori awal:

```powershell
docker compose up -d --wait postgres mailpit
docker compose run --rm --no-deps api php artisan migrate --seed
docker compose run --rm --no-deps api php artisan storage:link
docker compose up -d --wait api
```

Seeder kategori bisa diulang tanpa menduplikasi slug. Seeder tidak membuat akun pengguna bawaan.
`storage:link` cukup sekali; jika tautan sudah ada, tidak perlu membuatnya kembali.

6. Verifikasi jalur HTTP dan client Dart:

```powershell
curl.exe -i http://127.0.0.1:8000/api/v1/health
dart run tool/check_backend.dart http://127.0.0.1:8000/api/v1/
```

## Pemakaian sehari-hari

```powershell
docker compose up -d --wait
docker compose ps
flutter devices
flutter run -t lib/main_local.dart
```

Menutup Flutter tidak menghentikan backend. Untuk menghentikan layanan:

```powershell
docker compose stop
```

Named volumes `postgres_data` dan `backend_vendor` mempertahankan database dan dependency container.
Hindari `docker compose down -v` karena menghapus volume project.

## Alamat jaringan

| Pemanggil | API base URL | Database |
| --- | --- | --- |
| Komputer host | http://127.0.0.1:8000/api/v1/ | 127.0.0.1:5433 |
| Android Emulator | http://10.0.2.2:8000/api/v1/ | Melalui API |
| Container Laravel | Tidak perlu memanggil API sendiri | postgres:5432 |

Pengguna database lokal: `jaringan_kasih`. Database belajar: `jaringan_kasih`.
Kredensial contoh di Compose hanya untuk lingkungan lokal; file `.env` diabaikan Git.
Container Laravel mengganti DB_HOST/DB_PORT dari contoh `.env` melalui environment Compose.

`API_BASE_URL` mengatur alamat API yang dipanggil Flutter. `APP_URL` di backend dipakai saat membentuk
tautan absolut, termasuk URL storage dan tautan email. Nilai contoh APP_URL=127.0.0.1 sesuai akses
dari komputer; jangan langsung memakai URL tersebut sebagai tautan untuk emulator/HP.
Pembentukan URL gambar dan email yang sesuai perangkat akan ditetapkan bersama fitur P2/P3.

### HP fisik

Gunakan IP LAN komputer (lihat `ipconfig`) dan jaringan yang dapat saling mengakses.
API secara default hanya dipublikasikan ke loopback. Untuk sesi pengujian LAN:

```powershell
$env:API_BIND_ADDRESS = '0.0.0.0'
docker compose up -d --no-deps --force-recreate --wait api
flutter run -t lib/main_local.dart --dart-define=API_BASE_URL=http://IP_KOMPUTER:8000/api/v1/
```

Ganti `IP_KOMPUTER` dengan IP LAN yang sebenarnya. Jika diminta Windows Firewall, izinkan hanya jaringan privat yang digunakan.
Setelah sesi LAN selesai, kembalikan bind lokal:

```powershell
Remove-Item Env:API_BIND_ADDRESS -ErrorAction SilentlyContinue
docker compose up -d --no-deps --force-recreate --wait api
```

## Pengujian

```powershell
docker compose exec api php artisan test
flutter test --no-pub
```

Backend menguji health HTTP, respons error, PostgreSQL nyata, unique slug, dan seeder idempotent.
Flutter menguji parsing API, error 401/422, respons tidak valid, timeout, loading, dan retry.
Test HTTP Dart memakai server loopback sementara; widget test memakai hasil health yang dikontrol.
Pengujian otomatis ini tidak membuktikan akses dari HP/emulator; itu diuji melalui `main_local.dart`.

### Pemisahan database test

`infra/postgres/init-testing.sql` membuat `jaringan_kasih_testing` pada inisialisasi volume PostgreSQL pertama.
`phpunit.xml` memaksa penggunaan database tersebut pada environment dan variabel server PHP.
Docker mengisi keduanya, sedangkan PHPUnit `<env force="true">` sendiri tidak mengganti `$_SERVER`.
Laravel dapat tetap membaca APP_ENV=local atau nama database belajar jika kedua sumber tidak selaras.
`TestingEnvironmentTest` memeriksa pengaturan ini tanpa membuka koneksi database.
Test integrasi tetap memeriksa nama database aktual sebelum RefreshDatabase.
RefreshDatabase membuat ulang tabel di database test dan memakai transaksi untuk isolasi kasus.

Jika database test tidak ditemukan, periksa daftar database dulu:

```powershell
docker compose exec postgres psql -U jaringan_kasih -d postgres -c "SELECT datname FROM pg_database WHERE datname = 'jaringan_kasih_testing';"
```

Hanya jika hasilnya kosong, buat database test tanpa menghapus volume:

```powershell
docker compose exec postgres createdb -U jaringan_kasih -O jaringan_kasih jaringan_kasih_testing
```

## Troubleshooting

### CLI database berhasil tetapi HTTP health mengembalikan 503

`artisan serve` tanpa `--no-reload` menyaring environment proses anak. Akibatnya HTTP dapat membaca DB_HOST=127.0.0.1
dari `.env`, sedangkan CLI membaca DB_HOST=postgres dari Compose. Perintah server di Compose dan Dockerfile
memakai `--no-reload` agar environment Docker dipertahankan. Setelah mengubah environment Compose:

```powershell
docker compose up -d --no-deps --force-recreate --wait api
```

Perubahan nilai `.env` yang dimasukkan melalui `env_file` juga membutuhkan pembuatan ulang container.
`/up` adalah liveness (proses Laravel hidup); `/api/v1/health` adalah readiness database.
Status healthy container saat ini memakai `/up`, sehingga tetap periksa endpoint database.

### Docker 500 / WSL distro gagal

Periksa `docker version`, `docker network ls`, dan status di Docker Desktop.
Jika perlu restart WSL, simpan pekerjaan WSL, Quit Docker Desktop, jalankan `wsl --shutdown`, lalu buka Docker kembali.
Perintah tersebut menghentikan semua distro WSL yang sedang berjalan.
Jangan menghapus distro atau mereset data Docker sebagai langkah pertama karena image dan volume dapat hilang.

### Melihat log

```powershell
docker compose logs --tail 50 api
docker compose exec api sh -c 'tail -n 50 storage/logs/laravel.log'
```

### Email pengujian

Buka http://127.0.0.1:8025. Mailpit menangkap email di lingkungan lokal; tidak mengirimnya ke inbox internet.
Pengiriman email dari fitur akun baru diuji saat P2. Compose meneruskan MAIL_HOST=mailpit dan MAIL_PORT=1025.
