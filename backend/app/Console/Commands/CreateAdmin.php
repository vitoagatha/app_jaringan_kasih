<?php

namespace App\Console\Commands;

use App\Models\User;
use App\Support\PasswordRules;
use Illuminate\Console\Command;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class CreateAdmin extends Command
{
    protected $signature = 'admin:create {email? : Alamat email akun admin baru}';

    protected $description = 'Membuat akun admin baru secara interaktif tanpa password bawaan';

    public function handle(): int
    {
        $email = Str::lower(trim($this->argument('email') ?? $this->ask('Email admin')));
        $emailValidator = Validator::make(['email' => $email], [
            'email' => ['required', 'string', 'email', 'max:254', 'unique:users,email'],
        ]);
        if ($emailValidator->fails()) {
            $this->error('Email tidak valid atau sudah digunakan. Gunakan email baru; akun yang sudah ada tidak diubah.');

            return self::FAILURE;
        }
        $name = $this->ask('Nama admin');
        $password = $this->secret('Password admin (minimal 8 karakter, maksimal 72 byte)');
        $confirmation = $this->secret('Ulangi password admin');
        $validator = Validator::make(['name' => $name, 'password' => $password, 'password_confirmation' => $confirmation], [
            'name' => ['required', 'string', 'max:100'],
            'password' => PasswordRules::newPassword(),
        ]);
        if ($validator->fails()) {
            foreach ($validator->errors()->all() as $error) {
                $this->error($error);
            }

            return self::FAILURE;
        }
        try {
            $admin = new User(['name' => trim($name), 'email' => $email, 'password' => $password]);
            $admin->forceFill(['role' => 'admin'])->save();
        } catch (UniqueConstraintViolationException) {
            $this->error('Email sudah digunakan. Tidak ada akun yang diubah.');

            return self::FAILURE;
        }
        $this->info('Akun admin berhasil dibuat. Masuk melalui /admin/login.');

        return self::SUCCESS;
    }
}
