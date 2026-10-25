<?php

use App\Support\ApiResponse;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware) {
        // API harus menghasilkan 401, termasuk request tanpa Accept: application/json.
        // Callback default route('login') gagal sebelum exception auth bisa dirender.
        $middleware->redirectGuestsTo(fn (Request $request) => $request->is('api/*') ? null : '/');
    })
    ->withExceptions(function (Exceptions $exceptions) {
        $exceptions->shouldRenderJsonWhen(fn (Request $request) => $request->is('api/*') || $request->expectsJson());
        $exceptions->render(function (Throwable $exception, Request $request) {
            if (! $request->is('api/*')) {
                return null;
            }
            if ($exception instanceof ValidationException) {
                return ApiResponse::error('Data yang dikirim belum valid.', 422, $exception->errors());
            }
            if ($exception instanceof AuthenticationException) {
                return ApiResponse::error('Silakan masuk kembali.', 401);
            }
            if ($exception instanceof AuthorizationException) {
                return ApiResponse::error('Anda tidak memiliki izin untuk tindakan ini.', 403);
            }
            $status = $exception instanceof HttpExceptionInterface ? $exception->getStatusCode() : 500;
            $message = match ($status) {
                401 => 'Silakan masuk kembali.',
                403 => 'Anda tidak memiliki izin untuk tindakan ini.',
                404 => 'Endpoint atau data tidak ditemukan.',
                405 => 'Metode HTTP tidak didukung.',
                413 => 'Ukuran unggahan melebihi batas server.',
                429 => 'Terlalu banyak permintaan. Silakan coba lagi nanti.',
                default => 'Terjadi kesalahan pada server.',
            };

            return ApiResponse::error($message, $status)
                ->withHeaders($exception instanceof HttpExceptionInterface ? $exception->getHeaders() : []);
        });
    })->create();
