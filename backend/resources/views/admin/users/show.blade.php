@extends('admin.layout')
@section('title', 'Detail pengguna')
@section('heading', 'Detail pengguna')
@section('description', 'Informasi akun dan status verifikasi pengguna.')
@section('actions')<a href="{{ route('admin.users.index') }}" class="btn">Kembali ke daftar</a>@endsection
@section('content')
<div class="row g-4"><div class="col-lg-4"><div class="card"><div class="card-body text-center py-5"><span class="avatar avatar-xl admin-avatar mb-3">{{ mb_strtoupper(mb_substr($user->name, 0, 1)) }}</span><h2 class="mb-1 text-break">{{ $user->name }}</h2><p class="text-secondary text-break">{{ $user->email }}</p><span class="badge badge-soft">{{ $user->isAdmin() ? 'Administrator' : 'Pengguna aplikasi' }}</span></div></div></div><div class="col-lg-8"><div class="card"><div class="card-header"><h2 class="card-title">Informasi akun</h2></div><div class="card-body"><dl class="account-details"><div><dt>ID pengguna</dt><dd>#{{ $user->id }}</dd></div><div><dt>Nama</dt><dd>{{ $user->name }}</dd></div><div><dt>Email</dt><dd>{{ $user->email }}</dd></div><div><dt>Status email</dt><dd>@include('admin.partials.verification', ['user' => $user])</dd></div><div><dt>Tanggal verifikasi</dt><dd>{{ $user->email_verified_at?->format('d M Y, H:i') ?? 'Belum terverifikasi' }}</dd></div><div><dt>Bergabung</dt><dd>{{ $user->created_at->format('d M Y, H:i') }}</dd></div><div><dt>Diperbarui</dt><dd>{{ $user->updated_at->format('d M Y, H:i') }}</dd></div></dl></div></div></div></div>
<section class="card mt-4">
    <div class="card-header"><h2 class="card-title">Status akses akun</h2><div class="ms-auto">@include('admin.partials.account-status', ['user' => $user])</div></div>
    <div class="card-body"><div class="row g-4">
        <div class="col-lg-6">
            @if($user->isAdmin())<div class="alert alert-info mb-0"><x-admin.icon name="shield" /><span>Akun admin dilindungi. Statusnya tidak dapat diubah melalui dashboard.</span></div>
            @else<p class="text-secondary">Akun nonaktif tidak dapat masuk atau menggunakan fitur terlindungi. Data profil, pendanaan, dan wishlist tetap disimpan.</p>@endif
            <dl class="account-details">
                <div><dt>Perubahan terakhir</dt><dd>{{ $user->status_changed_at?->format('d M Y, H:i') ?? 'Belum pernah diubah' }}</dd></div>
                @if($user->status_changed_at)
                    <div><dt>Diubah oleh</dt><dd>{{ $user->statusChangedBy?->name ?? 'Admin sudah tidak tersedia' }}</dd></div>
                    <div><dt>Alasan terakhir</dt><dd class="activity-text">{{ $user->status_reason }}</dd></div>
                @endif
            </dl>
            <a class="btn btn-sm mt-3" href="{{ route('admin.activities.index', ['subject_type' => 'user', 'subject_id' => $user->id]) }}"><x-admin.icon name="clock" /> Lihat riwayat akun</a>
        </div>
        @unless($user->isAdmin())
        <div class="col-lg-6">
            <form id="user-status-form" method="post" action="{{ route('admin.users.status', $user) }}">
                @csrf @method('PATCH')
                <input type="hidden" name="is_active" value="{{ $user->is_active ? '0' : '1' }}">
                <input type="hidden" name="status_version" value="{{ $user->status_version }}">
                <label for="reason" class="form-label required">Alasan {{ $user->is_active ? 'penonaktifan' : 'pengaktifan kembali' }}</label>
                <textarea class="form-control @error('reason') is-invalid @enderror" id="reason" name="reason" rows="4" maxlength="1000" required placeholder="Jelaskan alasan tindakan ini">{{ old('reason') }}</textarea>
                @error('reason')<div class="invalid-feedback">{{ $message }}</div>@enderror
                <div class="form-hint">Alasan wajib diisi, maksimal 1.000 karakter, dan akan tersimpan di aktivitas admin.</div>
                <button class="btn {{ $user->is_active ? 'btn-outline-danger' : 'btn-primary' }} mt-3" type="button" data-bs-toggle="modal" data-bs-target="#user-status-modal">{{ $user->is_active ? 'Nonaktifkan akun' : 'Aktifkan kembali' }}</button>
            </form>
        </div>
        @endunless
    </div></div>
</section>
@unless($user->isAdmin())
<div class="modal fade" id="user-status-modal" tabindex="-1" aria-labelledby="user-status-title" aria-hidden="true"><div class="modal-dialog modal-dialog-centered"><div class="modal-content">
    <div class="modal-header"><h2 class="modal-title" id="user-status-title">{{ $user->is_active ? 'Nonaktifkan akun pengguna?' : 'Aktifkan kembali akun?' }}</h2><button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Tutup"></button></div>
    <div class="modal-body"><p>Akun <strong class="text-break">{{ $user->name }}</strong> akan {{ $user->is_active ? 'dinonaktifkan' : 'diaktifkan kembali' }}.</p><p class="mb-0 text-secondary">{{ $user->is_active ? 'Token aktif akan dibuat tidak berlaku. Pengguna tidak dapat login sampai akunnya diaktifkan kembali.' : 'Pengguna dapat login kembali. Token lama tetap tidak berlaku; pengguna harus masuk ulang.' }}</p></div>
    <div class="modal-footer"><button class="btn" type="button" data-bs-dismiss="modal">Batal</button><button class="btn {{ $user->is_active ? 'btn-danger' : 'btn-primary' }}" type="submit" form="user-status-form">Ya, {{ $user->is_active ? 'nonaktifkan' : 'aktifkan kembali' }}</button></div>
</div></div></div>
@endunless
@endsection
