<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Support\ApiResponse;
use App\Support\PasswordRules;
use App\Support\UserData;
use Illuminate\Auth\Events\PasswordReset;
use Illuminate\Auth\Events\Verified;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class AccountController extends Controller
{
    private function normalizeEmail(Request $request): void
    {
        if (is_string($request->input('email'))) {
            $request->merge(['email' => Str::lower(trim($request->input('email')))]);
        }
    }

    public function update(Request $request): JsonResponse
    {
        $this->normalizeEmail($request);
        $data = $request->validate([
            'name' => ['required', 'string', 'max:100'],
            'email' => ['required', 'string', 'email', 'max:254', Rule::unique('users')->ignore($request->user()->id)],
            'current_password' => ['nullable', 'string', 'max:72'],
        ]);
        try {
            $user = DB::transaction(function () use ($request, $data) {
                $user = User::whereKey($request->user()->id)->lockForUpdate()->firstOrFail();
                if ($data['email'] !== $user->email) {
                    if (! Hash::check($data['current_password'] ?? '', $user->password)) {
                        throw ValidationException::withMessages(['current_password' => ['Password saat ini tidak sesuai.']]);
                    }
                    DB::table('password_reset_tokens')->whereIn('email', [$user->email, $data['email']])->delete();
                    $user->tokens()->whereKeyNot($request->user()->currentAccessToken()->id)->delete();
                    $user->email_verified_at = null;
                }
                $user->name = $data['name'];
                $user->email = $data['email'];
                $user->save();

                return $user;
            });
        } catch (UniqueConstraintViolationException $exception) {
            throw ValidationException::withMessages(['email' => ['Email sudah digunakan.']]);
        }

        return ApiResponse::success(['user' => UserData::from($user)], 'Profil disimpan.')->header('Cache-Control', 'no-store');
    }

    public function changePassword(Request $request): JsonResponse
    {
        $data = $request->validate([
            'current_password' => ['required', 'string', 'max:72'],
            'password' => PasswordRules::newPassword(),
        ]);
        DB::transaction(function () use ($request, $data) {
            $user = User::whereKey($request->user()->id)->lockForUpdate()->firstOrFail();
            if (! Hash::check($data['current_password'], $user->password)) {
                throw ValidationException::withMessages(['current_password' => ['Password saat ini tidak sesuai.']]);
            }
            $user->forceFill(['password' => $data['password'], 'remember_token' => Str::random(60)])->save();
            $user->tokens()->delete();
            DB::table('password_reset_tokens')->where('email', $user->email)->delete();
        });

        return ApiResponse::success(null, 'Password diubah. Silakan login kembali.')->header('Cache-Control', 'no-store');
    }

    public function forgotPassword(Request $request): JsonResponse
    {
        $this->normalizeEmail($request);
        $data = $request->validate(['email' => ['required', 'string', 'email', 'max:254']]);
        Password::sendResetLink($data);

        // Respons identik untuk akun terdaftar, tidak terdaftar, dan broker throttle.
        return ApiResponse::success(null, 'Jika email terdaftar, petunjuk reset dikirim.')->header('Cache-Control', 'no-store');
    }

    public function resetPassword(Request $request): JsonResponse
    {
        $this->normalizeEmail($request);
        $data = $request->validate([
            'email' => ['required', 'string', 'email', 'max:254'],
            'token' => ['required', 'string', 'size:64'],
            'password' => PasswordRules::newPassword(),
        ]);
        $status = DB::transaction(function () use ($data) {
            // Serialisasi reset/login/perubahan password untuk user yang sama.
            User::where('email', $data['email'])->lockForUpdate()->first();

            return Password::reset($data, function (User $user, string $password) {
                $user->forceFill(['password' => $password, 'remember_token' => Str::random(60)])->save();
                $user->tokens()->delete();
                event(new PasswordReset($user));
            });
        });
        if ($status !== Password::PASSWORD_RESET) {
            throw ValidationException::withMessages(['token' => ['Token atau email tidak valid, sudah dipakai, atau kedaluwarsa.']]);
        }

        return ApiResponse::success(null, 'Password direset. Silakan login kembali.')->header('Cache-Control', 'no-store');
    }

    public function sendVerification(Request $request): JsonResponse
    {
        if ($request->user()->hasVerifiedEmail()) {
            return ApiResponse::success(null, 'Email sudah terverifikasi.');
        }
        $request->user()->sendEmailVerificationNotification();

        return ApiResponse::success(null, 'Tautan verifikasi dikirim ke email.');
    }

    public function verify(Request $request, int $id, string $hash): JsonResponse
    {
        $user = DB::transaction(function () use ($id, $hash) {
            $user = User::whereKey($id)->lockForUpdate()->firstOrFail();
            abort_unless(hash_equals(sha1($user->getEmailForVerification()), $hash), 403);
            if (! $user->hasVerifiedEmail() && $user->markEmailAsVerified()) {
                event(new Verified($user));
            }

            return $user;
        });

        return ApiResponse::success(null, 'Email terverifikasi. Kembali ke aplikasi dan periksa sesi.')->header('Cache-Control', 'no-store');
    }
}
