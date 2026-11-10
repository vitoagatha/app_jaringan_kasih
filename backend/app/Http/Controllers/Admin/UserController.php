<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;
use Illuminate\View\View;

class UserController extends Controller
{
    public function index(Request $request): View
    {
        $filters = $request->validate([
            'search' => ['nullable', 'string', 'max:100'],
            'verification' => ['nullable', 'in:verified,unverified'],
            'role' => ['nullable', 'in:user,admin'],
        ]);
        $query = User::query();
        if ($search = trim($filters['search'] ?? '')) {
            $pattern = '%'.addcslashes($search, '\\%_').'%';
            $query->where(fn (Builder $query) => $query->where('name', 'ilike', $pattern)->orWhere('email', 'ilike', $pattern));
        }
        if ($role = $filters['role'] ?? null) {
            $query->where('role', $role);
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
        return view('admin.users.show', compact('user'));
    }
}
