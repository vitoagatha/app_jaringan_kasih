<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AdminActivityLog;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\View\View;

class ActivityController extends Controller
{
    public function index(Request $request): View
    {
        $filters = $request->validate([
            'actor_id' => ['nullable', 'integer', Rule::exists('users', 'id')->where('role', 'admin')],
            'event' => ['nullable', Rule::in(array_keys(AdminActivityLog::EVENTS))],
            'date_from' => ['nullable', 'date_format:Y-m-d'],
            'date_to' => ['nullable', 'date_format:Y-m-d', ...($request->filled('date_from') ? ['after_or_equal:date_from'] : [])],
            'subject_type' => ['nullable', 'required_with:subject_id', Rule::in(['user', 'category'])],
            'subject_id' => ['nullable', 'required_with:subject_type', 'integer', 'min:1'],
        ]);
        $query = AdminActivityLog::query();
        foreach (['actor_id', 'event', 'subject_type', 'subject_id'] as $field) {
            if (isset($filters[$field])) {
                $query->where($field, $filters[$field]);
            }
        }
        if (isset($filters['date_from'])) {
            $query->whereDate('created_at', '>=', $filters['date_from']);
        }
        if (isset($filters['date_to'])) {
            $query->whereDate('created_at', '<=', $filters['date_to']);
        }

        return view('admin.activities.index', [
            'activities' => $query->orderByDesc('created_at')->orderByDesc('id')->paginate(20)->withQueryString(),
            'actors' => User::where('role', 'admin')->orderBy('name')->get(['id', 'name']),
            'events' => AdminActivityLog::EVENTS,
        ]);
    }

    public function show(AdminActivityLog $activity): View
    {
        return view('admin.activities.show', compact('activity'));
    }
}
