<?php

namespace Tests\Feature;

use App\Models\Category;
use Database\Seeders\CategorySeeder;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use LogicException;
use Tests\TestCase;

class PostgresFoundationTest extends TestCase
{
    use RefreshDatabase;

    protected function beforeRefreshingDatabase(): void
    {
        // Pemeriksaan berlangsung SEBELUM RefreshDatabase boleh menjalankan migrate:fresh.
        if (! app()->environment('testing') || config('database.default') !== 'pgsql') {
            throw new LogicException(sprintf(
                'Test database wajib memakai environment testing dan PostgreSQL (APP_ENV=%s, DB_CONNECTION=%s).',
                app()->environment(),
                config('database.default'),
            ));
        }

        $database = DB::selectOne('SELECT current_database() AS name')->name;
        if ($database !== 'jaringan_kasih_testing') {
            throw new LogicException('Test dihentikan: koneksi tidak menunjuk ke jaringan_kasih_testing.');
        }
    }

    public function test_health_checks_a_real_postgresql_connection(): void
    {
        $this->getJson('/api/v1/health')->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.database', 'connected')
            ->assertJsonPath('data.service', 'jaringan-kasih-api')
            ->assertJsonStructure(['data' => ['timestamp']]);
    }

    public function test_category_seeding_is_repeatable_without_creating_duplicates(): void
    {
        $this->seed(CategorySeeder::class);
        $this->seed(CategorySeeder::class);

        $this->assertDatabaseCount('categories', 6);
        $this->assertSame([
            'bencana-alam', 'kesehatan', 'lingkungan', 'pendidikan', 'rumah-ibadah', 'zakat',
        ], Category::query()->orderBy('slug')->pluck('slug')->all());
        $this->assertDatabaseHas('categories', ['name' => 'Rumah Ibadah', 'slug' => 'rumah-ibadah']);
    }

    public function test_postgresql_rejects_duplicate_category_slugs(): void
    {
        Category::create(['name' => 'Pendidikan', 'slug' => 'pendidikan']);

        $this->expectException(QueryException::class);
        Category::create(['name' => 'Duplikat', 'slug' => 'pendidikan']);
    }
}
