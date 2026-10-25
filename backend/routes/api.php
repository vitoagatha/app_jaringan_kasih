<?php

use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\HealthController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::get('health', HealthController::class)->name('api.v1.health');
    Route::prefix('auth')->name('api.v1.auth.')->group(function () {
        Route::post('register', [AuthController::class, 'register'])->middleware('throttle:auth-register')->name('register');
        Route::post('login', [AuthController::class, 'login'])->middleware('throttle:auth-login')->name('login');
        Route::middleware('auth:sanctum')->group(function () {
            Route::get('me', [AuthController::class, 'me'])->name('me');
            Route::post('logout', [AuthController::class, 'logout'])->name('logout');
        });
    });
});
