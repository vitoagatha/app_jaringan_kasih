<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\User;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function __invoke(): View
    {
        $users = User::query()->where('role', 'user');
        $total = (clone $users)->count();
        $verified = (clone $users)->whereNotNull('email_verified_at')->count();
        $daily = (clone $users)->where('created_at', '>=', now()->subDays(6)->startOfDay())
            ->selectRaw('DATE(created_at) AS day, COUNT(*) AS total')
            ->groupByRaw('DATE(created_at)')->pluck('total', 'day');
        $days = collect(range(6, 0))->map(function (int $offset) use ($daily) {
            $day = now()->subDays($offset);

            return ['label' => $day->locale('id')->translatedFormat('D'), 'date' => $day->format('d/m'),
                'count' => (int) ($daily[$day->toDateString()] ?? 0)];
        });

        return view('admin.dashboard', [
            'totalUsers' => $total,
            'verifiedUsers' => $verified,
            'unverifiedUsers' => $total - $verified,
            'totalCategories' => Category::count(),
            'recentUsers' => (clone $users)->latest('id')->limit(6)->get(),
            'days' => $days,
            'weeklyTotal' => $days->sum('count'),
            'dailyMax' => max(1, $days->max('count')),
        ]);
    }
}
