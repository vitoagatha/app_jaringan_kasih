<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpFoundation\Response;

class AuthController extends Controller
{
    public function create(Request $request): Response
    {
        if ($request->user('web')?->isAdmin()) {
            return redirect()->route('admin.dashboard');
        }

        return response()->view('admin.auth.login')->header('Cache-Control', 'no-store, private');
    }

    public function store(Request $request): RedirectResponse
    {
        if (is_string($request->input('email'))) {
            $request->merge(['email' => Str::lower(trim($request->input('email')))]);
        }
        $data = $request->validate([
            'email' => ['required', 'string', 'email', 'max:254'],
            'password' => ['bail', 'required', 'string', 'max:72', function ($attribute, $value, $fail) {
                if (strlen($value) > 72) {
                    $fail('Password maksimal 72 byte.');
                }
            }],
        ]);
        if (! Auth::guard('web')->attempt([...$data, 'role' => 'admin'])) {
            throw ValidationException::withMessages(['email' => 'Email atau password admin tidak sesuai.']);
        }
        $request->session()->regenerate();

        // Always start inside the admin panel; do not follow arbitrary intended URLs.
        return redirect()->route('admin.dashboard');
    }

    public function destroy(Request $request): RedirectResponse
    {
        Auth::guard('web')->logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('admin.login')->with('status', 'Anda sudah keluar dari panel admin.');
    }
}
