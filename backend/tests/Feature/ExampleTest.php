<?php

namespace Tests\Feature;

use Tests\TestCase;

class ExampleTest extends TestCase
{
    public function test_the_root_describes_the_api_without_exposing_configuration(): void
    {
        $this->getJson('/')->assertOk()->assertExactJson([
            'success' => true,
            'message' => 'Permintaan berhasil.',
            'data' => [
                'service' => 'jaringan-kasih-api',
                'version' => 'v1',
                'health_path' => '/api/v1/health',
            ],
        ]);
    }
}
