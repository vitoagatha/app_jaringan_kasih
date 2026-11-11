@extends('admin.layout')
@section('title', 'Aktivitas admin')
@section('heading', 'Aktivitas admin')
@section('description', 'Telusuri tindakan admin, waktu pelaksanaan, dan objek yang berubah.')
@section('content')
@if(request('subject_type'))<div class="alert alert-info">Menampilkan riwayat {{ request('subject_type') === 'user' ? 'pengguna' : 'kategori' }} #{{ request('subject_id') }}. <a href="{{ route('admin.activities.index') }}" class="ms-2">Lihat seluruh aktivitas</a></div>@endif
<div class="card">
    <div class="card-body border-bottom"><form method="get" action="{{ route('admin.activities.index') }}" class="row g-3 align-items-end">
        @if(request('subject_type'))<input type="hidden" name="subject_type" value="{{ request('subject_type') }}"><input type="hidden" name="subject_id" value="{{ request('subject_id') }}">@endif
        <div class="col-md-6 col-xl-3"><label class="form-label" for="actor_id">Admin pelaksana</label><select class="form-select" id="actor_id" name="actor_id"><option value="">Semua admin</option>@foreach($actors as $actor)<option value="{{ $actor->id }}" @selected((string) request('actor_id') === (string) $actor->id)>{{ $actor->name }}</option>@endforeach</select></div>
        <div class="col-md-6 col-xl-3"><label class="form-label" for="event">Jenis tindakan</label><select class="form-select" id="event" name="event"><option value="">Semua tindakan</option>@foreach($events as $value => $label)<option value="{{ $value }}" @selected(request('event') === $value)>{{ $label }}</option>@endforeach</select></div>
        <div class="col-sm-6 col-xl-2"><label class="form-label" for="date_from">Dari tanggal</label><input class="form-control" type="date" name="date_from" id="date_from" value="{{ request('date_from') }}"></div>
        <div class="col-sm-6 col-xl-2"><label class="form-label" for="date_to">Sampai tanggal</label><input class="form-control" type="date" name="date_to" id="date_to" value="{{ request('date_to') }}"></div>
        <div class="col-xl-2 d-flex gap-2"><button class="btn btn-primary" type="submit"><x-admin.icon name="search" /> Filter</button><a class="btn" href="{{ route('admin.activities.index') }}">Reset</a></div>
    </form></div>
    <div class="card-header"><h2 class="card-title">Riwayat tindakan</h2><span class="badge badge-soft ms-auto">{{ $activities->total() }} aktivitas</span></div>
    <div class="table-responsive"><table class="table table-vcenter card-table"><thead><tr><th>Waktu</th><th>Admin pelaksana</th><th>Tindakan</th><th>Objek</th><th><span class="visually-hidden">Detail</span></th></tr></thead><tbody>
        @forelse($activities as $activity)<tr><td class="text-nowrap text-secondary">{{ $activity->created_at->format('d M Y') }}<small class="d-block">{{ $activity->created_at->format('H:i:s') }}</small></td><td class="text-break">{{ $activity->actor_name }}</td><td><span class="badge badge-soft">{{ $events[$activity->event] ?? $activity->event }}</span></td><td><strong class="text-break">{{ $activity->subject_label }}</strong><small class="d-block text-secondary">{{ $activity->subject_type === 'user' ? 'Pengguna' : 'Kategori' }} #{{ $activity->subject_id }}</small></td><td><a class="btn btn-sm" href="{{ route('admin.activities.show', $activity) }}">Detail <x-admin.icon name="arrow" /></a></td></tr>
        @empty<tr><td colspan="5"><div class="empty-state"><x-admin.icon name="clock" /><strong>Belum ada aktivitas yang sesuai</strong><p>Tindakan admin mulai dicatat sejak fitur ini diaktifkan. Coba ubah filter jika diperlukan.</p></div></td></tr>@endforelse
    </tbody></table></div>
    @include('admin.partials.pagination', ['paginator' => $activities])
</div>
<p class="text-secondary small mt-3">Waktu ditampilkan dalam {{ config('app.timezone') }}. Riwayat tidak dapat diedit atau dihapus melalui dashboard.</p>
@endsection
