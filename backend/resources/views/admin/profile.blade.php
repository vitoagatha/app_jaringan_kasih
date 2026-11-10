@extends('admin.layout')
@section('title', 'Profil admin')
@section('heading', 'Profil dan keamanan')
@section('description', 'Perbarui informasi akun dan jaga keamanan akses admin Anda.')
@section('content')
<div class="row g-4"><div class="col-lg-4"><div class="card"><div class="card-body text-center py-4"><span class="avatar avatar-xl admin-avatar mb-3">{{ mb_strtoupper(mb_substr($user->name, 0, 1)) }}</span><h2 class="text-break mb-1">{{ $user->name }}</h2><p class="text-secondary text-break">{{ $user->email }}</p><span class="badge badge-soft badge-admin">Administrator</span><div class="mt-3">@include('admin.partials.verification', ['user' => $user])</div></div>@unless($user->hasVerifiedEmail())<div class="card-footer"><form method="post" action="{{ route('admin.profile.verification') }}">@csrf<button type="submit" class="btn w-100"><x-admin.icon name="mail" /> Kirim tautan verifikasi</button></form></div>@endunless</div></div>
<div class="col-lg-8 d-flex flex-column gap-4">
    <form class="card" action="{{ route('admin.profile.update') }}" method="post">@csrf @method('PATCH')
        <div class="card-header"><h2 class="card-title">Informasi profil</h2></div><div class="card-body">
            <div class="mb-3"><label for="name" class="form-label required">Nama</label><input class="form-control" id="name" name="name" value="{{ old('name', $user->name) }}" maxlength="100" autocomplete="name" required></div>
            <div class="mb-3"><label for="email" class="form-label required">Email</label><input class="form-control" id="email" type="email" name="email" value="{{ old('email', $user->email) }}" maxlength="254" autocomplete="email" required></div>
            <div><label for="profile-current-password" class="form-label">Password saat ini</label><input class="form-control" id="profile-current-password" type="password" name="current_password" autocomplete="current-password"><div class="form-hint">Wajib diisi jika mengganti email. Email baru perlu diverifikasi kembali.</div></div>
        </div><div class="card-footer text-end"><button class="btn btn-primary" type="submit">Simpan profil</button></div>
    </form>
    <form class="card" action="{{ route('admin.profile.password') }}" method="post">@csrf @method('PUT')
        <div class="card-header"><h2 class="card-title">Ubah password</h2></div><div class="card-body">
            <div class="mb-3"><label for="current-password" class="form-label required">Password saat ini</label><input class="form-control" type="password" id="current-password" name="current_password" autocomplete="current-password" required></div>
            <div class="mb-3"><label for="new-password" class="form-label required">Password baru</label><input class="form-control" type="password" id="new-password" name="password" minlength="8" autocomplete="new-password" required><div class="form-hint">Minimal 8 karakter dan maksimal 72 byte. Gunakan password yang berbeda dari sebelumnya.</div></div>
            <div><label for="password-confirmation" class="form-label required">Konfirmasi password baru</label><input class="form-control" type="password" id="password-confirmation" name="password_confirmation" minlength="8" autocomplete="new-password" required></div>
            <div class="alert alert-info mt-4 mb-0"><x-admin.icon name="shield" /><span>Setelah password berubah, sesi lain dan token aplikasi harus masuk kembali. Browser ini tetap dapat digunakan.</span></div>
        </div><div class="card-footer text-end"><button class="btn btn-primary" type="submit"><x-admin.icon name="lock" /> Perbarui password</button></div>
    </form>
</div></div>
@endsection
