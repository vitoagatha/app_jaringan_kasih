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

Form Requests, Policies, repository fitur Flutter, dan Sanctum ditambahkan mengikuti P1-P5.
Belum ada endpoint registrasi/login pada P0.

## Endpoint yang tersedia

| Metode | Path | Kegunaan |
| --- | --- | --- |
| GET | `/` | Informasi layanan |
| GET | `/up` | Proses Laravel hidup; respons bawaan framework |
| GET | `/api/v1/health` | Pemeriksaan query `SELECT 1` ke database |

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
Token provider masih titik integrasi; penyimpanan/penerbitan token dikerjakan P1.

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
