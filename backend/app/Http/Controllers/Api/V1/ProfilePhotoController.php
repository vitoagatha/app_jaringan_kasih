<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Support\ApiResponse;
use App\Support\UserData;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use RuntimeException;
use Throwable;

class ProfilePhotoController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'photo' => ['required', 'file', 'image', 'mimes:jpg,jpeg,png,webp', 'max:2048', 'dimensions:min_width=32,min_height=32,max_width=4096,max_height=4096'],
        ], [
            'photo.required' => 'Pilih foto terlebih dahulu.',
            'photo.uploaded' => 'Unggah gagal. Periksa ukuran file dan coba lagi.',
            'photo.file' => 'Foto harus berupa file.',
            'photo.image' => 'File harus berupa gambar yang valid.',
            'photo.mimes' => 'Gunakan JPEG, PNG, atau WebP.',
            'photo.max' => 'Foto maksimal 2 MB.',
            'photo.dimensions' => 'Dimensi foto harus antara 32 dan 4096 piksel pada setiap sisi.',
        ]);
        $path = Storage::disk('public')->putFile('avatars', $request->file('photo'));
        if (! $path) {
            throw new RuntimeException('Photo storage failed.');
        }
        try {
            [$user, $oldPath] = DB::transaction(function () use ($request, $path) {
                $user = User::whereKey($request->user()->id)->lockForUpdate()->firstOrFail();
                $oldPath = $user->photo_path;
                $user->forceFill(['photo_path' => $path])->save();

                return [$user, $oldPath];
            });
        } catch (Throwable $exception) {
            Storage::disk('public')->delete($path);
            throw $exception;
        }
        if ($oldPath) {
            Storage::disk('public')->delete($oldPath);
        }

        return ApiResponse::success(['user' => UserData::from($user)], 'Foto profil disimpan.')->header('Cache-Control', 'no-store');
    }

    public function destroy(Request $request): JsonResponse
    {
        [$user, $oldPath] = DB::transaction(function () use ($request) {
            $user = User::whereKey($request->user()->id)->lockForUpdate()->firstOrFail();
            $oldPath = $user->photo_path;
            $user->forceFill(['photo_path' => null])->save();

            return [$user, $oldPath];
        });
        if ($oldPath) {
            Storage::disk('public')->delete($oldPath);
        }

        return ApiResponse::success(['user' => UserData::from($user)], 'Foto profil dihapus.')->header('Cache-Control', 'no-store');
    }
}
