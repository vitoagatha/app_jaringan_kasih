# Backend Jaringan Kasih

Laravel 12 API, PHP 8.2+, dan PostgreSQL. Jalur utama menjalankan backend adalah Docker Compose dari root repository.

- Panduan setup: [LOCAL_DEVELOPMENT.md](../docs/LOCAL_DEVELOPMENT.md)
- Kontrak API: [ARCHITECTURE.md](../docs/ARCHITECTURE.md)
- Prioritas: [ROADMAP.md](../docs/ROADMAP.md)

## Perintah dari root repository

```powershell
docker compose up -d --wait
docker compose exec api php artisan route:list --path=api
docker compose exec api php artisan test
```

`/up` memeriksa proses aplikasi; `/api/v1/health` juga memeriksa koneksi database.
Saat ini auth Sanctum dan endpoint fitur belum diimplementasikan (mulai P1).

## Database test

`phpunit.xml` memaksa APP_ENV=testing dan DB_DATABASE=jaringan_kasih_testing pada environment dan variabel server PHP.
Test integrasi memiliki guard yang membaca nama database aktual sebelum menjalankan RefreshDatabase.
Jangan menggunakan database belajar atau database berisi data penting sebagai database test.

## Penyimpanan

Konfigurasi memakai disk public pada filesystem lokal. File publik akan berada pada
`storage/app/public`; `php artisan storage:link` membuat tautan aksesnya.
Implementasi upload dan validasi gambar dikerjakan pada P3.
