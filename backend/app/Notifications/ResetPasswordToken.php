<?php

namespace App\Notifications;

use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class ResetPasswordToken extends Notification
{
    public function __construct(private readonly string $token) {}

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        return (new MailMessage)
            ->subject('Reset password Jaringan Kasih')
            ->greeting('Halo, '.$notifiable->name)
            ->line('Buka menu Lupa password → Atur password baru di aplikasi.')
            ->line('Masukkan email akun dan salin token berikut:')
            ->line($this->token)
            ->line('Token berlaku 60 menit dan hanya dapat dipakai sekali.')
            ->line('Jika tidak meminta reset, abaikan email ini.');
    }
}
