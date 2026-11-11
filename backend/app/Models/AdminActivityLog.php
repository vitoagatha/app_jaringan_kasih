<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use LogicException;

class AdminActivityLog extends Model
{
    public const UPDATED_AT = null;

    public const EVENTS = [
        'user.deactivated' => 'Pengguna dinonaktifkan',
        'user.activated' => 'Pengguna diaktifkan',
        'category.created' => 'Kategori ditambahkan',
        'category.updated' => 'Kategori diperbarui',
        'category.deleted' => 'Kategori dihapus',
        'admin.profile_updated' => 'Profil admin diperbarui',
        'admin.password_changed' => 'Password admin diubah',
    ];

    protected $guarded = ['*'];

    protected function casts(): array
    {
        return ['before_values' => 'array', 'after_values' => 'array'];
    }

    protected static function booted(): void
    {
        static::updating(fn () => throw new LogicException('Riwayat aktivitas tidak dapat diubah.'));
        static::deleting(fn () => throw new LogicException('Riwayat aktivitas tidak dapat dihapus.'));
    }
}
