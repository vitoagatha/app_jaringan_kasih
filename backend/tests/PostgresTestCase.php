<?php

namespace Tests;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use LogicException;

abstract class PostgresTestCase extends TestCase
{
    use RefreshDatabase;

    protected function beforeRefreshingDatabase(): void
    {
        if (! app()->environment('testing') || config('database.default') !== 'pgsql') {
            throw new LogicException(sprintf(
                'Test database wajib memakai environment testing dan PostgreSQL (APP_ENV=%s, DB_CONNECTION=%s).',
                app()->environment(),
                config('database.default'),
            ));
        }
        if (DB::selectOne('SELECT current_database() AS name')->name !== 'jaringan_kasih_testing') {
            throw new LogicException('Test dihentikan: koneksi tidak menunjuk ke jaringan_kasih_testing.');
        }
    }
}
