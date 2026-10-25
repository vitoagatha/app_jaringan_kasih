<?php

use App\Http\Controllers\Api\V1\AccountController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\HealthController;
use App\Http\Controllers\Api\V1\ProfilePhotoController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::get('health', HealthController::class)->name('api.v1.health');
    Route::prefix('auth')->name('api.v1.auth.')->group(function () {
        Route::post('register', [AuthController::class, 'register'])->middleware('throttle:auth-register')->name('register');
        Route::post('login', [AuthController::class, 'login'])->middleware('throttle:auth-login')->name('login');
        Route::post('forgot-password', [AccountController::class, 'forgotPassword'])->middleware('throttle:account-public')->name('forgot-password');
        Route::post('reset-password', [AccountController::class, 'resetPassword'])->middleware('throttle:account-public')->name('reset-password');
        Route::get('email/verify/{id}/{hash}', [AccountController::class, 'verify'])
            ->middleware(['signed:relative', 'throttle:30,1'])->whereNumber('id')->name('verify');
        Route::middleware('auth:sanctum')->group(function () {
            Route::get('me', [AuthController::class, 'me'])->name('me');
            Route::post('logout', [AuthController::class, 'logout'])->name('logout');
            Route::patch('profile', [AccountController::class, 'update'])->middleware('throttle:account-write')->name('profile');
            Route::post('change-password', [AccountController::class, 'changePassword'])->middleware('throttle:account-write')->name('change-password');
            Route::post('email/verification-notification', [AccountController::class, 'sendVerification'])->middleware('throttle:verification-mail')->name('verification-notification');
            Route::post('profile/photo', [ProfilePhotoController::class, 'store'])->middleware('throttle:account-write')->name('photo.store');
            Route::delete('profile/photo', [ProfilePhotoController::class, 'destroy'])->middleware('throttle:account-write')->name('photo.destroy');
        });
    });
});
