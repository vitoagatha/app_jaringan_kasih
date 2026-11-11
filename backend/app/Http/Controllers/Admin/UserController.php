<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Support\AdminActivity;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;
use Illuminate\View\View;

class UserController extends Controller
{
    public function index(Request $request): View
    {
        $filters = $request->validate([
            'search' => ['nullable', 'string', 'max:100'],
            'verification' => ['nullable', 'in:verified,unverified'],
            'role' => ['nullable', 'in:user,admin'],
            'status' => ['nullable', 'in:active,inactive'],
        ]);
        $query = User::query();
        if ($search = trim($filters['search'] ?? '')) {
            $pattern = '%'.addcslashes($search, '\\%_').'%';
            $query->where(fn (Builder $query) => $query->where('name', 'ilike', $pattern)->orWhere('email', 'ilike', $pattern));
        }
        if ($role = $filters['role'] ?? null) {
            $query->where('role', $role);
        }
        if ($status = $filters['status'] ?? null) {
            $query->where('is_active', $status === 'active');
        }
        if (($filters['verification'] ?? null) === 'verified') {
            $query->whereNotNull('email_verified_at');
        } elseif (($filters['verification'] ?? null) === 'unverified') {
            $query->whereNull('email_verified_at');
        }

        return view('admin.users.index', ['users' => $query->latest('id')->paginate(15)->withQueryString()]);
    }

    public function show(User $user): View
    {
        $user->load('statusChangedBy:id,name');

        return view('admin.users.show', compact('user'));
    }

    public function status(Request $request, User $user): RedirectResponse
    {
        $data = $request->validate([
            'is_active' => ['required', 'boolean'],
            'reason' => ['required', 'string', 'max:1000'],
            'status_version' => ['required', 'integer', 'min:0'],
        ]);
        DB::transaction(function () use ($request, $user, $data) {
            $target = User::whereKey($user->id)->lockForUpdate()->firstOrFail();
            abort_if($target->isAdmin() || $target->id === $request->user('web')->id, 403, 'Status akun admin tidak dapat diubah.');
            $active = $request->boolean('is_active');
            if ($target->status_version !== (int) $data['status_version'] || $target->is_active === $active) {
                throw ValidationException::withMessages(['status' => 'Status akun telah berubah. Muat ulang halaman sebelum mencoba lagi.']);
            }
            $before = ['is_active' => $target->is_active];
            $target->forceFill([
                'is_active' => $active,
                'status_reason' => trim($data['reason']),
                'status_changed_by' => $request->user('web')->id,
                'status_changed_at' => now(),
                'status_version' => $target->status_version + 1,
                'remember_token' => Str::random(60),
            ])->save();
            if (! $active) {
                // Expired tokens cannot be reused, even after reactivation. Keeping
                // their hashes allows a specific disabled-account response until pruning.
                $target->tokens()->where(fn ($query) => $query->whereNull('expires_at')->orWhere('expires_at', '>=', now()))
                    ->update(['expires_at' => now()->subSecond()]);
            }
            AdminActivity::record($request->user('web'), $active ? 'user.activated' : 'user.deactivated',
                $target, $before, ['is_active' => $active], $target->status_reason);
        });

        return redirect()->route('admin.users.show', $user)->with('status', 'Status akun pengguna berhasil diperbarui.');
    }
}
