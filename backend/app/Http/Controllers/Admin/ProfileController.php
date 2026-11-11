<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Support\AdminActivity;
use App\Support\PasswordRules;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;
use Illuminate\View\View;

class ProfileController extends Controller
{
    public function edit(Request $request): View
    {
        return view('admin.profile', ['user' => $request->user('web')]);
    }

    public function update(Request $request): RedirectResponse
    {
        if (is_string($request->input('email'))) {
            $request->merge(['email' => Str::lower(trim($request->input('email')))]);
        }
        $data = $request->validateWithBag('profile', [
            'name' => ['required', 'string', 'max:100'],
            'email' => ['required', 'string', 'email', 'max:254', Rule::unique('users')->ignore($request->user('web')->id)],
            'current_password' => ['nullable', 'string', 'max:72'],
        ]);
        try {
            DB::transaction(function () use ($request, $data) {
                $user = User::whereKey($request->user('web')->id)->lockForUpdate()->firstOrFail();
                $before = $user->only(['name', 'email']);
                if ($data['email'] !== $user->email) {
                    if (! Hash::check($data['current_password'] ?? '', $user->password)) {
                        throw ValidationException::withMessages(['current_password' => 'Masukkan password saat ini untuk mengganti email.'])->errorBag('profile');
                    }
                    $user->email_verified_at = null;
                }
                $user->fill(['name' => trim($data['name']), 'email' => $data['email']])->save();
                $changed = array_intersect_key($user->getChanges(), array_flip(['name', 'email']));
                if ($changed !== []) {
                    AdminActivity::record($request->user('web'), 'admin.profile_updated', $user,
                        array_intersect_key($before, $changed), $changed);
                }
            });
        } catch (UniqueConstraintViolationException) {
            throw ValidationException::withMessages(['email' => 'Email sudah digunakan.'])->errorBag('profile');
        }

        return back()->with('status', 'Profil admin berhasil diperbarui. Jika email berubah, verifikasi kembali alamat baru Anda.');
    }

    public function password(Request $request): RedirectResponse
    {
        $data = $request->validateWithBag('password', [
            'current_password' => ['required', 'string', 'max:72'],
            'password' => [...PasswordRules::newPassword(), 'different:current_password'],
        ]);
        DB::transaction(function () use ($request, $data) {
            $user = User::whereKey($request->user('web')->id)->lockForUpdate()->firstOrFail();
            if (! Hash::check($data['current_password'], $user->password)) {
                throw ValidationException::withMessages(['current_password' => 'Password saat ini tidak sesuai.'])->errorBag('password');
            }
            $user->forceFill(['password' => $data['password'], 'remember_token' => Str::random(60)])->save();
            $user->tokens()->delete();
            AdminActivity::record($request->user('web'), 'admin.password_changed', $user);
        });
        // Keep this browser signed in; auth.session rejects older password hashes elsewhere.
        $request->user('web')->refresh();
        $request->session()->put('password_hash_web', $request->user('web')->getAuthPassword());
        $request->session()->regenerate();

        return back()->with('status', 'Password berhasil diubah. Sesi lain dan token aplikasi harus masuk kembali.');
    }

    public function verification(Request $request): RedirectResponse
    {
        if (! $request->user('web')->hasVerifiedEmail()) {
            $request->user('web')->sendEmailVerificationNotification();
        }

        return back()->with('status', 'Jika email belum terverifikasi, tautan verifikasi telah dikirim.');
    }
}
