@extends('admin.layout')
@section('title', 'Detail pengguna')
@section('heading', 'Detail pengguna')
@section('description', 'Informasi akun dan status verifikasi pengguna.')
@section('actions')<a href="{{ route('admin.users.index') }}" class="btn">Kembali ke daftar</a>@endsection
@section('content')
<div class="row g-4"><div class="col-lg-4"><div class="card"><div class="card-body text-center py-5"><span class="avatar avatar-xl admin-avatar mb-3">{{ mb_strtoupper(mb_substr($user->name, 0, 1)) }}</span><h2 class="mb-1 text-break">{{ $user->name }}</h2><p class="text-secondary text-break">{{ $user->email }}</p><span class="badge badge-soft">{{ $user->isAdmin() ? 'Administrator' : 'Pengguna aplikasi' }}</span></div></div></div><div class="col-lg-8"><div class="card"><div class="card-header"><h2 class="card-title">Informasi akun</h2></div><div class="card-body"><dl class="account-details"><div><dt>ID pengguna</dt><dd>#{{ $user->id }}</dd></div><div><dt>Nama</dt><dd>{{ $user->name }}</dd></div><div><dt>Email</dt><dd>{{ $user->email }}</dd></div><div><dt>Status email</dt><dd>@include('admin.partials.verification', ['user' => $user])</dd></div><div><dt>Tanggal verifikasi</dt><dd>{{ $user->email_verified_at?->format('d M Y, H:i') ?? 'Belum terverifikasi' }}</dd></div><div><dt>Bergabung</dt><dd>{{ $user->created_at->format('d M Y, H:i') }}</dd></div><div><dt>Diperbarui</dt><dd>{{ $user->updated_at->format('d M Y, H:i') }}</dd></div></dl></div></div></div></div>
@endsection
