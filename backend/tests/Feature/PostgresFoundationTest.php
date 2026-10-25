<?php

namespace Tests\Feature;

use App\Models\Category;
use Database\Seeders\CategorySeeder;
use Illuminate\Database\QueryException;
use Tests\PostgresTestCase;

class PostgresFoundationTest extends PostgresTestCase
{
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
