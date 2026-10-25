<?php

namespace App\Http\Requests\Auth;

class RegisterRequest extends LoginRequest
{
    public function rules(): array
    {
        $rules = parent::rules();
        $rules['name'] = ['required', 'string', 'max:100'];
        $rules['email'][] = 'unique:users,email';
        $rules['password'][] = 'min:8';
        $rules['password'][] = 'confirmed';

        return $rules;
    }
}
