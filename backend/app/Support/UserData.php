<?php

namespace App\Support;

use App\Models\User;

final class UserData
{
    public static function from(User $user): array
    {
        return [
            ...$user->only(['id', 'name', 'email', 'email_verified_at']),
            // URL relatif menggunakan host API yang dipakai perangkat, bukan APP_URL host PC.
            'photo_url' => $user->photo_path ? '/storage/'.$user->photo_path : null,
        ];
    }
}
