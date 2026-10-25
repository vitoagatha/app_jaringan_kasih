<?php

namespace Tests\Feature;

use Illuminate\Support\Facades\DB;
use PDOException;
use Tests\TestCase;

class HealthFailureTest extends TestCase
{
    public function test_database_failure_returns_503_without_leaking_connection_details(): void
    {
        DB::shouldReceive('select')->once()->with('SELECT 1')
            ->andThrow(new PDOException('host=internal password=secret'));

        $this->getJson('/api/v1/health')->assertStatus(503)->assertExactJson([
            'success' => false,
            'message' => 'Koneksi database belum tersedia.',
            'errors' => [
                'database' => ['Periksa layanan PostgreSQL dan konfigurasi backend.'],
            ],
        ])->assertDontSee('password=secret');
    }
}
