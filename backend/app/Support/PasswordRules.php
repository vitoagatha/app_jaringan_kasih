<?php

namespace App\Support;

final class PasswordRules
{
    public static function newPassword(): array
    {
        return ['bail', 'required', 'string', 'min:8', 'confirmed', function ($attribute, $value, $fail) {
            if (strlen($value) > 72) {
                $fail('Password maksimal 72 byte.');
            }
        }];
    }
}
