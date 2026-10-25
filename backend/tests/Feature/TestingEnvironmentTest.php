<?php

namespace Tests\Feature;

use Tests\TestCase;

class TestingEnvironmentTest extends TestCase
{
    public function test_phpunit_configuration_overrides_the_local_container_environment(): void
    {
        // Tidak membuka koneksi database: verifikasi konfigurasi sebelum test integrasi.
        $this->assertSame('testing', app()->environment());
        $this->assertSame('pgsql', config('database.default'));
        $this->assertSame('jaringan_kasih_testing', config('database.connections.pgsql.database'));
        $this->assertSame('array', config('cache.default'));
        $this->assertSame('array', config('session.driver'));
        $this->assertSame('array', config('mail.default'));
        $this->assertSame('sync', config('queue.default'));
        $this->assertSame(4, (int) config('hashing.bcrypt.rounds'));
    }
}
