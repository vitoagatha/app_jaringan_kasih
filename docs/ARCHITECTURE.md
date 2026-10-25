# Arsitektur dan kontrak API

## Aliran data

Flutter -> HTTP JSON / multipart -> Laravel -> PostgreSQL dan disk lokal.
Laravel -> SMTP Mailpit untuk email pengujian.

Flutter tidak menerima password database atau secret backend. File gambar disimpan pada disk;
database menyimpan path relatif. URL untuk client dibentuk backend saat implementasi gambar P3.

## Struktur

| Bagian | Peran |
| --- | --- |
| `backend/routes/api.php` | Route API dengan prefix `/api/v1` |
| `backend/app/Http/Controllers/Api/V1` | Pengaturan alur request |
| `backend/app/Support/ApiResponse.php` | Envelope respons konsisten |
| `backend/bootstrap/app.php` | Routing dan pemetaan exception API |
| `backend/app/Models` | Model Eloquent |
| `backend/database/migrations` | Struktur SQL yang dilacak versi |
| `backend/database/seeders` | Data kategori awal |
| `lib/core/config` | API_BASE_URL melalui dart-define |
| `lib/core/network` | HTTP client, token provider, timeout, dan exception |
| `lib/features/health` | Model hasil health dan repository |
| `lib/main_local.dart` | Layar diagnostik P0 |

P1 menambahkan Form Requests autentikasi dan Sanctum. Policies serta repository
fitur Flutter mengikuti implementasi fitur. Kontrak dan status P1 tercatat pada
[AUTHENTICATION.md](AUTHENTICATION.md).

## Endpoint yang tersedia

Kategori, pendanaan, dan wishlist P4/P5 memakai tabel fundings/wishlists dan client
`lib/features/funding`. Kontrak/hak akses/pagination tersedia pada
[FUNDING_AND_WISHLIST.md](FUNDING_AND_WISHLIST.md). Client memakai ApiClient dan
token sesi yang sama dengan fitur akun. Source dan dependency Firestore lama telah
dihapus pada P6. Layout/error/siklus sesi dijelaskan pada [QUALITY_AND_CLEANUP.md](QUALITY_AND_CLEANUP.md).

Kontrak tambahan profil, email/password, dan foto P2/P3 tercatat pada
[ACCOUNT_AND_PHOTOS.md](ACCOUNT_AND_PHOTOS.md). URL foto adalah path relatif
ke origin API perangkat; tautan verifikasi email memakai APP_URL backend.

| Metode | Path | Kegunaan |
| --- | --- | --- |
| GET | `/` | Informasi layanan |
| GET | `/up` | Proses Laravel hidup; respons bawaan framework |
| GET | `/api/v1/health` | Pemeriksaan query `SELECT 1` ke database |
| POST | `/api/v1/auth/register` | Registrasi dan penerbitan token |
| POST | `/api/v1/auth/login` | Login dan penerbitan token |
| GET | `/api/v1/auth/me` | Pengguna pemilik token aktif |
| POST | `/api/v1/auth/logout` | Pencabutan token aktif |

`/api/v1/` sendiri bukan endpoint daftar data dan akan mengembalikan 404.

## Respons JSON API v1

Berhasil (HTTP 200, atau status sukses lain sesuai endpoint):

```json
{"success":true,"message":"API dan database siap digunakan.","data":{"service":"jaringan-kasih-api","database":"connected","timestamp":"2026-10-25T00:00:00+00:00"}}
```

Gagal:

```json
{"success":false,"message":"Data yang dikirim belum valid.","errors":{"email":["Email tidak valid."]}}
```

| Status | Makna |
| --- | --- |
| 401 | Autentikasi tidak tersedia/tidak valid |
| 403 | Pengguna tidak memiliki izin |
| 404 | Route atau data tidak ditemukan |
| 405 | Metode HTTP tidak didukung |
| 422 | Validasi input gagal; errors berisi pesan per field |
| 429 | Batas request tercapai |
| 500 | Kesalahan server; detail internal tidak dikirim ke client |
| 503 | Readiness database gagal |

Pemetaan status tersedia sebagai fondasi; endpoint fitur terkait dikembangkan pada tahap berikutnya.
`ApiClient` mengubah kegagalan HTTP menjadi `ApiException` yang membawa status dan pesan per field.
Ia tidak mengikuti redirect, serta membatasi endpoint agar tetap berada di dalam API_BASE_URL.
Token backend diterbitkan Sanctum. Fitur Flutter `lib/features/auth` mencakup
repository API, SecureTokenStore, SessionController, serta form/gate sesi.
Entrypoint utama menggunakan alur ini; pengguna melaporkan build serta alur manual
registrasi, login, pemulihan sesi, logout, dan validasi PASS di Android Emulator.

### Batas waktu dan penutupan client

Deadline mencakup pembacaan token, pembukaan koneksi, dan pembacaan respons.
Setelah timeout, token atau koneksi yang baru selesai tidak boleh melanjutkan pengiriman request.
Request yang terlambat terbentuk dibatalkan dan pembacaan respons dihentikan.
Menutup client juga mencegah request baru atau pengiriman setelah token selesai dibaca.

Timeout pada client tidak menjamin operasi yang sudah diterima server ikut dibatalkan.
Pencegahan submit ganda dan idempotensi operasi tulis tetap menjadi tanggung jawab fitur terkait.
Test regresi mencakup token/koneksi terlambat, client ditutup, dan pengiriman POST JSON dengan bearer token.

## Fondasi data P0

- `users`: identitas, password hash, waktu verifikasi, photo_path nullable.
- `password_reset_tokens`: struktur reset password bawaan Laravel.
- `sessions`, `cache`, `cache_locks`, `jobs`, `job_batches`, `failed_jobs`: tabel infrastruktur bawaan.
- `categories`: name, slug unik, timestamp; enam kategori diisi secara idempotent.

P0 menggunakan file untuk cache/sesi dan queue sync; tabel infrastruktur tersedia tetapi tidak harus aktif dipakai.
Database belajar dan database test terpisah. Akun/data Firebase lama belum dimigrasikan.
