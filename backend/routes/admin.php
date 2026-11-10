<?php

use App\Http\Controllers\Admin\AuthController;
use App\Http\Controllers\Admin\CategoryController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\ProfileController;
use App\Http\Controllers\Admin\UserController;
use Illuminate\Support\Facades\Route;

Route::prefix('admin')->name('admin.')->group(function () {
    Route::get('login', [AuthController::class, 'create'])->name('login');
    Route::post('login', [AuthController::class, 'store'])->middleware('throttle:admin-login')->name('login.store');

    Route::middleware(['auth:web', 'auth.session', 'admin'])->group(function () {
        Route::get('/', DashboardController::class)->name('dashboard');
        Route::post('logout', [AuthController::class, 'destroy'])->name('logout');
        Route::get('users', [UserController::class, 'index'])->name('users.index');
        Route::get('users/{user}', [UserController::class, 'show'])->whereNumber('user')->name('users.show');
        Route::resource('categories', CategoryController::class)->except('show')->whereNumber('category');
        Route::get('profile', [ProfileController::class, 'edit'])->name('profile.edit');
        Route::patch('profile', [ProfileController::class, 'update'])->middleware('throttle:account-write')->name('profile.update');
        Route::put('profile/password', [ProfileController::class, 'password'])->middleware('throttle:account-write')->name('profile.password');
        Route::post('profile/verification', [ProfileController::class, 'verification'])->middleware('throttle:verification-mail')->name('profile.verification');
    });
});
