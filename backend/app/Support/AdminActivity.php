<?php

namespace App\Support;

use App\Models\AdminActivityLog;
use App\Models\Category;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Arr;
use LogicException;

final class AdminActivity
{
    public static function record(User $actor, string $event, Model $subject, array $before = [], array $after = [], ?string $reason = null): AdminActivityLog
    {
        if (! $actor->isAdmin() || ! array_key_exists($event, AdminActivityLog::EVENTS)) {
            throw new LogicException('Pelaksana atau jenis aktivitas admin tidak valid.');
        }
        $allowed = match ($event) {
            'user.deactivated', 'user.activated' => ['is_active'],
            'category.created', 'category.updated', 'category.deleted' => ['name', 'slug'],
            'admin.profile_updated' => ['name', 'email'],
            'admin.password_changed' => [],
        };
        // Only explicitly permitted fields enter the log. Passwords, hashes and tokens never do.
        $before = Arr::only($before, $allowed);
        $after = Arr::only($after, $allowed);
        $log = new AdminActivityLog;
        $log->forceFill([
            'actor_id' => $actor->id,
            'actor_name' => $actor->name,
            'event' => $event,
            'subject_type' => match (true) {
                $subject instanceof User => 'user',
                $subject instanceof Category => 'category',
                default => throw new LogicException('Objek aktivitas tidak didukung.'),
            },
            'subject_id' => $subject->getKey(),
            'subject_label' => $subject->name,
            'before_values' => $before ?: null,
            'after_values' => $after ?: null,
            'reason' => in_array($event, ['user.deactivated', 'user.activated'], true) ? $reason : null,
        ])->save();

        return $log;
    }
}
