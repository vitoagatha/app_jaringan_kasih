@extends('admin.layout')
@section('title', 'Pengguna')
@section('heading', 'Pengguna')
@section('description', 'Temukan pengguna dan lihat informasi akun yang terdaftar.')
@section('content')
<div class="card">
    <div class="card-body border-bottom"><form method="get" action="{{ route('admin.users.index') }}" class="row g-3 align-items-end">
        <div class="col-lg-5"><label for="search" class="form-label">Cari pengguna</label><input class="form-control" id="search" name="search" maxlength="100" value="{{ request('search') }}" placeholder="Nama atau alamat email"></div>
        <div class="col-sm-6 col-lg-3"><label for="verification" class="form-label">Verifikasi email</label><select class="form-select" id="verification" name="verification"><option value="">Semua status</option><option value="verified" @selected(request('verification') === 'verified')>Terverifikasi</option><option value="unverified" @selected(request('verification') === 'unverified')>Belum verifikasi</option></select></div>
        <div class="col-sm-6 col-lg-2"><label for="role" class="form-label">Peran</label><select class="form-select" id="role" name="role"><option value="">Semua peran</option><option value="user" @selected(request('role') === 'user')>Pengguna</option><option value="admin" @selected(request('role') === 'admin')>Admin</option></select></div>
        <div class="col-lg-2 d-flex gap-2"><button class="btn btn-primary flex-grow-1" type="submit"><x-admin.icon name="search" /> Cari</button><a class="btn btn-icon" href="{{ route('admin.users.index') }}" aria-label="Reset filter">↺</a></div>
    </form></div>
    <div class="card-header"><h2 class="card-title">Daftar pengguna</h2><span class="badge badge-soft ms-auto">{{ $users->total() }} akun</span></div>
    <div class="table-responsive"><table class="table table-vcenter card-table"><thead><tr><th>Pengguna</th><th>Peran</th><th>Verifikasi email</th><th>Bergabung</th><th><span class="visually-hidden">Aksi</span></th></tr></thead><tbody>
    @forelse($users as $user)<tr><td><div class="person-cell"><span class="avatar admin-avatar">{{ mb_strtoupper(mb_substr($user->name, 0, 1)) }}</span><div class="person-info"><a href="{{ route('admin.users.show', $user) }}">{{ $user->name }}</a><span>{{ $user->email }}</span></div></div></td><td><span class="badge badge-soft {{ $user->isAdmin() ? 'badge-admin' : '' }}">{{ $user->isAdmin() ? 'Admin' : 'Pengguna' }}</span></td><td>@include('admin.partials.verification', ['user' => $user])</td><td class="text-nowrap text-secondary">{{ $user->created_at->format('d M Y') }}</td><td><a class="btn btn-sm" href="{{ route('admin.users.show', $user) }}">Detail <x-admin.icon name="arrow" /></a></td></tr>
    @empty<tr><td colspan="5"><div class="empty-state"><x-admin.icon name="users" /><strong>Tidak ada pengguna yang sesuai</strong><p>Coba kata kunci atau filter lainnya.</p></div></td></tr>@endforelse
    </tbody></table></div>
    @include('admin.partials.pagination', ['paginator' => $users])
</div>
@endsection
