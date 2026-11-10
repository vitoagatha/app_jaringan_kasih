@extends('admin.base')
@section('title', 'Masuk admin')
@section('body')
<main class="admin-login">
    <section class="login-story" aria-label="Jaringan Kasih">
        <a class="login-brand" href="{{ route('admin.login') }}"><img src="{{ asset('images/jaringan-kasih.png') }}" alt="Logo Jaringan Kasih" width="64" height="64"><span>Jaringan Kasih</span></a>
        <div class="story-copy"><div class="story-overline">RUANG KELOLA KOMUNITAS</div><h1>Kebaikan dimulai<br>dari kepedulian.</h1><p>Satu ruang untuk mengenal pengguna, merawat komunitas, dan menata setiap langkah kebaikan.</p><div class="story-line"></div><span>Semua dapat membantu.</span></div>
        <div class="story-footer"><x-admin.icon name="shield" /> Akses khusus administrator</div>
    </section>
    <section class="login-panel" aria-labelledby="login-title">
        <div class="login-form-wrap">
            <div class="login-emblem"><x-admin.icon name="lock" /></div>
            <div class="page-pretitle mb-2">SELAMAT DATANG KEMBALI</div>
            <h2 id="login-title">Masuk ke panel admin</h2>
            <p class="text-secondary mb-4">Gunakan akun admin untuk mengelola Jaringan Kasih.</p>
            @if(session('status'))<div class="alert alert-success" role="status">{{ session('status') }}</div>@endif
            @if($errors->any())<div class="alert alert-danger" role="alert"><ul class="mb-0">@foreach($errors->all() as $message)<li>{{ $message }}</li>@endforeach</ul></div>@endif
            <form action="{{ route('admin.login.store') }}" method="post">
                @csrf
                <div class="mb-3"><label class="form-label" for="email">Email admin</label><input class="form-control @error('email') is-invalid @enderror" type="email" id="email" name="email" value="{{ old('email') }}" maxlength="254" autocomplete="username" placeholder="nama@contoh.id" required autofocus></div>
                <div class="mb-4"><label class="form-label" for="password">Password</label><div class="input-group input-group-flat"><input class="form-control" type="password" id="password" name="password" autocomplete="current-password" required><button class="btn password-toggle" type="button" data-toggle-password="password" aria-controls="password" aria-pressed="false">Lihat</button></div></div>
                <button class="btn btn-primary w-100 login-submit" type="submit">Masuk ke dashboard <x-admin.icon name="arrow" class="ms-2" /></button>
            </form>
            <p class="login-help"><x-admin.icon name="shield" /><span>Akun aplikasi biasa tidak memiliki akses ke panel ini. Hubungi pengelola jika Anda membutuhkan akses admin.</span></p>
            <div class="login-copyright">Jaringan Kasih · Panel administrasi</div>
        </div>
    </section>
</main>
@endsection
