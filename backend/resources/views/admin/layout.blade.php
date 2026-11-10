@extends('admin.base')
@section('body')
<a class="visually-hidden-focusable skip-link" href="#main-content">Lewati navigasi</a>
<div class="page">
    <aside class="navbar navbar-vertical navbar-expand-lg admin-sidebar" data-bs-theme="dark" aria-label="Navigasi admin">
        <div class="container-fluid">
            <a class="navbar-brand brand-lockup" href="{{ route('admin.dashboard') }}">
                <img src="{{ asset('images/jaringan-kasih.png') }}" width="44" height="44" alt="Logo Jaringan Kasih" class="brand-logo">
                <span>Jaringan Kasih<small>ADMIN WORKSPACE</small></span>
            </a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#sidebar-menu" aria-controls="sidebar-menu" aria-expanded="false" aria-label="Buka navigasi">
                <x-admin.icon name="menu" />
            </button>
            <div class="collapse navbar-collapse" id="sidebar-menu">
                <div class="sidebar-caption">RUANG KELOLA</div>
                <ul class="navbar-nav">
                    @foreach ([['admin.dashboard', 'home', 'Ringkasan', 'admin.dashboard'], ['admin.users.index', 'users', 'Pengguna', 'admin.users.*'], ['admin.categories.index', 'category', 'Kategori', 'admin.categories.*'], ['admin.profile.edit', 'shield', 'Profil admin', 'admin.profile.*']] as [$route, $icon, $label, $pattern])
                    <li class="nav-item">
                        <a class="nav-link {{ request()->routeIs($pattern) ? 'active' : '' }}" href="{{ route($route) }}" @if(request()->routeIs($pattern)) aria-current="page" @endif>
                            <span class="nav-link-icon"><x-admin.icon :name="$icon" /></span><span class="nav-link-title">{{ $label }}</span>
                        </a>
                    </li>
                    @endforeach
                </ul>
                <div class="sidebar-note">
                    <span class="note-dot"></span>
                    <p>Semua dapat membantu.<small>Kelola komunitas untuk tumbuh bersama.</small></p>
                </div>
                <div class="sidebar-account">
                    <span class="avatar avatar-sm admin-avatar">{{ mb_strtoupper(mb_substr(auth('web')->user()->name, 0, 1)) }}</span>
                    <div class="sidebar-account-name"><strong>{{ auth('web')->user()->name }}</strong><small>Administrator</small></div>
                    <form action="{{ route('admin.logout') }}" method="post">
                        @csrf
                        <button class="btn btn-icon sidebar-logout" type="submit" aria-label="Keluar dari panel admin" title="Keluar"><x-admin.icon name="logout" /></button>
                    </form>
                </div>
            </div>
        </div>
    </aside>
    <div class="page-wrapper">
        <header class="admin-topbar">
            <div class="container-xl d-flex align-items-center justify-content-between gap-3">
                <span class="topbar-label">Panel administrasi <span class="text-secondary mx-2">/</span> <strong>@yield('title')</strong></span>
                <a class="admin-profile-link" href="{{ route('admin.profile.edit') }}"><x-admin.icon name="shield" /> <span>Akun admin</span></a>
            </div>
        </header>
        <main id="main-content" class="admin-main">
            <div class="container-xl">
                <div class="page-header mb-4">
                    <div class="row align-items-center g-3">
                        <div class="col">
                            <div class="page-pretitle">Jaringan Kasih</div>
                            <h1 class="page-title">@yield('heading')</h1>
                            <p class="page-description">@yield('description')</p>
                        </div>
                        @hasSection('actions')<div class="col-auto">@yield('actions')</div>@endif
                    </div>
                </div>
                @if(session('status'))
                    <div class="alert alert-success" role="status"><x-admin.icon name="check" /><span>{{ session('status') }}</span></div>
                @endif
                @if(collect($errors->getBags())->contains(fn ($bag) => $bag->any()))
                    <div class="alert alert-danger" role="alert">
                        <div><strong>Periksa kembali data Anda.</strong><ul class="mb-0 mt-1">
                        @foreach($errors->getBags() as $bag) @foreach($bag->all() as $message)<li>{{ $message }}</li>@endforeach @endforeach
                        </ul></div>
                    </div>
                @endif
                @yield('content')
            </div>
        </main>
        <footer class="admin-footer"><div class="container-xl d-flex flex-wrap justify-content-between gap-2"><span>Jaringan Kasih · Semua dapat membantu.</span><span>Panel administrasi</span></div></footer>
    </div>
</div>
@endsection
