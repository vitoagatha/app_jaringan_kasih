<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Support\ApiResponse;
use App\Support\PhotoRules;
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
        $request->validate(['photo' => PhotoRules::rules(true)], PhotoRules::messages());
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
