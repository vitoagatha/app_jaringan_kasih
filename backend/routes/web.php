<?php

use App\Support\ApiResponse;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return ApiResponse::success([
        'service' => 'jaringan-kasih-api',
        'version' => 'v1',
        'health_path' => '/api/v1/health',
    ]);
});
