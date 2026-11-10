@extends('admin.layout')
@section('title', $category->exists ? 'Edit kategori' : 'Tambah kategori')
@section('heading', $category->exists ? 'Edit kategori' : 'Tambah kategori')
@section('description', 'Gunakan nama yang singkat dan mudah dikenali pengguna.')
@section('content')
<div class="row g-4"><div class="col-lg-8"><form class="card" method="post" action="{{ $category->exists ? route('admin.categories.update', $category) : route('admin.categories.store') }}">
    @csrf @if($category->exists) @method('PUT') @endif
    <div class="card-header"><h2 class="card-title">Informasi kategori</h2></div>
    <div class="card-body"><label class="form-label required" for="name">Nama kategori</label><input class="form-control @error('name') is-invalid @enderror" id="name" name="name" value="{{ old('name', $category->name) }}" maxlength="100" placeholder="Contoh: Pendidikan" required autofocus>@error('name')<div class="invalid-feedback">{{ $message }}</div>@enderror<div class="form-hint">Maksimal 100 karakter. Slug dibuat otomatis dari nama kategori.</div>@if($category->exists)<div class="mt-4"><span class="form-label">Slug saat ini</span><code>{{ $category->slug }}</code></div>@endif</div>
    <div class="card-footer d-flex flex-wrap justify-content-end gap-2"><a class="btn" href="{{ route('admin.categories.index') }}">Batal</a><button class="btn btn-primary" type="submit"><x-admin.icon name="check" /> Simpan kategori</button></div>
</form></div><div class="col-lg-4"><div class="card guidance-card"><div class="card-body"><span class="metric-icon tone-teal mb-3"><x-admin.icon name="category" /></span><h2 class="card-title">Tetap konsisten</h2><p class="text-secondary mb-0">Perubahan nama kategori juga digunakan oleh aplikasi mobile. Kategori yang masih dipakai hanya dapat diedit, bukan dihapus.</p></div></div></div></div>
@endsection
