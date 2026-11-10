@extends('admin.layout')
@section('title', 'Ringkasan')
@section('heading', 'Ringkasan komunitas')
@section('description', 'Lihat perkembangan pengguna dan kelola kebutuhan komunitas Anda.')
@section('actions')<span class="date-label"><x-admin.icon name="clock" /> {{ now()->locale('id')->translatedFormat('d F Y') }}</span>@endsection
@section('content')
<section class="welcome-card mb-4">
    <div><span class="welcome-kicker">RUANG UNTUK KEBAIKAN</span><h2>Halo, {{ auth('web')->user()->name }}.</h2><p>Komunitas yang terawat membuka lebih banyak kesempatan untuk membantu.</p><a href="{{ route('admin.users.index') }}" class="btn welcome-button">Lihat pengguna <x-admin.icon name="arrow" /></a></div>
    <div class="welcome-art" aria-hidden="true"><span></span><span></span><span></span><x-admin.icon name="users" /></div>
</section>
<div class="row g-3 mb-4">
    @foreach ([['Total pengguna', $totalUsers, 'users', 'Seluruh akun pengguna aplikasi', 'teal'], ['Email terverifikasi', $verifiedUsers, 'shield', 'Pengguna yang sudah verifikasi', 'green'], ['Belum terverifikasi', $unverifiedUsers, 'mail', 'Pengguna yang belum verifikasi', 'amber'], ['Kategori', $totalCategories, 'category', 'Pilihan kategori yang tersedia', 'blue']] as [$label, $value, $icon, $caption, $tone])
    <div class="col-sm-6 col-xl-3"><div class="card metric-card h-100"><div class="card-body"><div class="metric-heading"><span>{{ $label }}</span><span class="metric-icon tone-{{ $tone }}"><x-admin.icon :name="$icon" /></span></div><div class="metric-value">{{ number_format($value, 0, ',', '.') }}</div><div class="text-secondary small">{{ $caption }}</div></div></div></div>
    @endforeach
</div>
<div class="row g-4">
    <section class="col-xl-8"><div class="card h-100"><div class="card-header"><div><h2 class="card-title">Pengguna terbaru</h2><p class="card-subtitle">Kenali anggota yang baru bergabung.</p></div><a class="btn btn-sm btn-outline-primary ms-auto" href="{{ route('admin.users.index') }}">Lihat semua <x-admin.icon name="arrow" /></a></div>
        <div class="table-responsive"><table class="table table-vcenter card-table"><thead><tr><th>Pengguna</th><th>Verifikasi email</th><th>Bergabung</th><th><span class="visually-hidden">Detail</span></th></tr></thead><tbody>
        @forelse($recentUsers as $user)<tr><td><div class="person-cell"><span class="avatar admin-avatar">{{ mb_strtoupper(mb_substr($user->name, 0, 1)) }}</span><div class="person-info"><a href="{{ route('admin.users.show', $user) }}">{{ $user->name }}</a><span>{{ $user->email }}</span></div></div></td><td>@include('admin.partials.verification', ['user' => $user])</td><td class="text-secondary text-nowrap">{{ $user->created_at->format('d M Y') }}</td><td><a class="btn btn-icon btn-ghost-secondary" href="{{ route('admin.users.show', $user) }}" aria-label="Detail {{ $user->name }}"><x-admin.icon name="arrow" /></a></td></tr>
        @empty<tr><td colspan="4"><div class="empty-state"><x-admin.icon name="users" /><strong>Belum ada pengguna</strong><p>Pengguna yang mendaftar melalui aplikasi akan tampil di sini.</p></div></td></tr>@endforelse
        </tbody></table></div>
    </div></section>
    <div class="col-xl-4 d-flex flex-column gap-4">
        <section class="card"><div class="card-body"><div class="d-flex align-items-start justify-content-between"><div><h2 class="card-title">Pendaftaran 7 hari</h2><p class="text-secondary small">Pengguna aplikasi yang baru bergabung</p></div><span class="badge badge-soft">{{ $weeklyTotal }} akun</span></div><div class="registration-chart" role="img" aria-label="{{ $weeklyTotal }} pendaftaran selama tujuh hari terakhir">@foreach($days as $day)<div class="chart-column"><span class="chart-value">{{ $day['count'] }}</span><div class="chart-track"><div class="chart-bar" style="height: {{ $day['count'] / $dailyMax * 100 }}%"></div></div><span class="chart-day">{{ $day['label'] }}</span><span class="chart-date">{{ $day['date'] }}</span></div>@endforeach</div></div></section>
        <section class="card"><div class="card-body"><div class="d-flex align-items-center gap-2 mb-3"><span class="metric-icon tone-green"><x-admin.icon name="shield" /></span><h2 class="card-title mb-0">Verifikasi pengguna</h2></div><div class="verification-number">{{ $totalUsers ? round($verifiedUsers / $totalUsers * 100) : 0 }}<small>%</small></div><div class="progress progress-sm my-3" role="progressbar" aria-label="Pengguna dengan email terverifikasi" aria-valuenow="{{ $verifiedUsers }}" aria-valuemin="0" aria-valuemax="{{ max(1, $totalUsers) }}"><div class="progress-bar bg-primary" style="width: {{ $totalUsers ? $verifiedUsers / $totalUsers * 100 : 0 }}%"></div></div><p class="text-secondary small mb-3">{{ $verifiedUsers }} dari {{ $totalUsers }} pengguna sudah memverifikasi email.</p><a href="{{ route('admin.users.index', ['verification' => 'unverified', 'role' => 'user']) }}" class="text-primary fw-semibold">Lihat yang belum terverifikasi <x-admin.icon name="arrow" class="icon-sm" /></a></div></section>
    </div>
</div>
@endsection
