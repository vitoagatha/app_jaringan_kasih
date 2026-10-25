<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Throwable;

class HealthController extends Controller
{
    public function __invoke(): JsonResponse
    {
        try {
            DB::select('SELECT 1');
        } catch (Throwable $exception) {
            Log::warning('Database readiness check failed.', ['exception' => $exception::class]);

            return ApiResponse::error('Koneksi database belum tersedia.', 503, [
                'database' => ['Periksa layanan PostgreSQL dan konfigurasi backend.'],
            ]);
        }

        return ApiResponse::success([
            'service' => 'jaringan-kasih-api',
            'database' => 'connected',
            'timestamp' => now()->toIso8601String(),
        ], 'API dan database siap digunakan.');
    }
}
