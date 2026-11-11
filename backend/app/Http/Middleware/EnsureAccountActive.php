<?php

namespace App\Http\Middleware;

use App\Models\User;
use App\Support\ApiResponse;
use Closure;
use Illuminate\Http\Request;
use Laravel\Sanctum\PersonalAccessToken;
use Symfony\Component\HttpFoundation\Response;

class EnsureAccountActive
{
    public function handle(Request $request, Closure $next): Response
    {
        // Run before Sanctum so an expired token belonging to a disabled account
        // still receives the actionable account_disabled message, rather than a generic 401.
        $bearer = $request->bearerToken();
        $user = $bearer ? PersonalAccessToken::findToken($bearer)?->tokenable : $request->user();
        if ($user instanceof User && ! $user->is_active) {
            return ApiResponse::error('Akun Anda dinonaktifkan. Hubungi pengelola untuk bantuan.', 403, code: 'account_disabled')
                ->header('Cache-Control', 'no-store');
        }

        return $next($request);
    }
}
