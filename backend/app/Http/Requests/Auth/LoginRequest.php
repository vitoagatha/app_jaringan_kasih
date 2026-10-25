<?php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Str;

class LoginRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        if (is_string($this->input('email'))) {
            $this->merge(['email' => Str::lower(trim($this->input('email')))]);
        }
    }

    public function rules(): array
    {
        return [
            'email' => ['required', 'string', 'email', 'max:254'],
            // Bcrypt membatasi password berdasarkan byte, bukan jumlah karakter.
            'password' => ['required', 'string', 'max:72', function ($attribute, $value, $fail) {
                if (strlen($value) > 72) {
                    $fail('Password maksimal 72 byte.');
                }
            }],
            'device_name' => ['required', 'string', 'max:100'],
        ];
    }

    public function messages(): array
    {
        return [
            'required' => ':attribute wajib diisi.',
            'string' => ':attribute harus berupa teks.',
            'email.email' => 'Format email tidak valid.',
            'max' => ':attribute terlalu panjang.',
            'password.min' => 'Password minimal 8 karakter.',
            'password.confirmed' => 'Konfirmasi password tidak cocok.',
            'email.unique' => 'Email sudah digunakan.',
        ];
    }
}
