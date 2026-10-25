<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\LoginRequest;
use App\Http\Requests\Auth\RegisterRequest;
use App\Models\User;
use App\Support\ApiResponse;
use App\Support\UserData;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(RegisterRequest $request): JsonResponse
    {
        $data = $request->validated();
        try {
            return DB::transaction(function () use ($data) {
                $user = User::create([
                    'name' => $data['name'],
                    'email' => $data['email'],
                    'password' => $data['password'],
                ]);

                return $this->issueToken($user, $data['device_name'], 201);
            });
        } catch (UniqueConstraintViolationException $exception) {
            // Tetap validasi 422 bila dua registrasi email yang sama bersamaan.
            throw ValidationException::withMessages(['email' => ['Email sudah digunakan.']]);
        }
    }

    public function login(LoginRequest $request): JsonResponse
    {
        $data = $request->validated();

        return DB::transaction(function () use ($data) {
            $user = User::where('email', $data['email'])->lockForUpdate()->first();
            if (! $user || ! Hash::check($data['password'], $user->password)) {
                return ApiResponse::error('Email atau password tidak sesuai.', 401)
                    ->header('Cache-Control', 'no-store');
            }
            if (Hash::needsRehash($user->password)) {
                $user->forceFill(['password' => Hash::make($data['password'])])->save();
            }

            return $this->issueToken($user, $data['device_name']);
        });
    }

    public function me(Request $request): JsonResponse
    {
        return ApiResponse::success(['user' => $this->userData($request->user())])
            ->header('Cache-Control', 'no-store');
    }

    public function logout(Request $request): JsonResponse
    {
        // Hanya cabut sesi perangkat yang mengirim request ini.
        $request->user()->currentAccessToken()->delete();

        return ApiResponse::success(null, 'Berhasil keluar.')
            ->header('Cache-Control', 'no-store');
    }

    private function issueToken(User $user, string $deviceName, int $status = 200): JsonResponse
    {
        $expiresAt = now()->addDays(7);
        $token = $user->createToken($deviceName, ['*'], $expiresAt);

        return ApiResponse::success([
            'user' => $this->userData($user),
            'token' => $token->plainTextToken,
            'token_type' => 'Bearer',
            'expires_at' => $expiresAt->toIso8601String(),
        ], $status === 201 ? 'Registrasi berhasil.' : 'Berhasil masuk.', $status)
            ->header('Cache-Control', 'no-store');
    }

    private function userData(User $user): array
    {
        return UserData::from($user);
    }
}
