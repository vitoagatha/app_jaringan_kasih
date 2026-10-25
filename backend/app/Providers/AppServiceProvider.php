<?php

namespace App\Providers;

use Illuminate\Auth\Notifications\VerifyEmail;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\URL;
use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Str;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        VerifyEmail::createUrlUsing(function ($user) {
            $path = URL::temporarySignedRoute('api.v1.auth.verify', now()->addMinutes(60), [
                'id' => $user->getKey(), 'hash' => sha1($user->getEmailForVerification()),
            ], absolute: false);

            return rtrim(config('app.url'), '/').$path;
        });
        VerifyEmail::toMailUsing(fn ($user, $url) => (new MailMessage)
            ->subject('Verifikasi email Jaringan Kasih')
            ->greeting('Halo, '.$user->name)
            ->line('Konfirmasi alamat email akun Anda. Tautan berlaku 60 menit.')
            ->action('Verifikasi email', $url)
            ->line('Setelah berhasil, kembali ke aplikasi dan pilih Periksa sesi.'));
        RateLimiter::for('account-public', function (Request $request) {
            $email = $request->input('email');
            $identity = is_string($email) ? Str::lower(trim($email)) : '';

            return [Limit::perMinute(20)->by('account-ip:'.$request->ip()),
                Limit::perMinute(5)->by('account-email:'.hash('sha256', $identity.'|'.$request->ip()))];
        });
        RateLimiter::for('verification-mail', fn (Request $request) => Limit::perMinute(1)->by('verification:'.$request->user()->id));
        RateLimiter::for('account-write', fn (Request $request) => Limit::perMinute(20)->by('account-write:'.$request->user()->id));
        RateLimiter::for('auth-login', function (Request $request) {
            $email = $request->input('email');
            $identity = is_string($email) ? Str::lower(trim($email)) : '';

            return [
                Limit::perMinute(30)->by('login-ip:'.$request->ip()),
                Limit::perMinute(5)->by('login-account:'.hash('sha256', $identity.'|'.$request->ip())),
            ];
        });
        RateLimiter::for('auth-register', fn (Request $request) => Limit::perMinute(5)->by('register:'.$request->ip()));
    }
}
