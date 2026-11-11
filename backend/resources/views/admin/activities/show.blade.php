@extends('admin.layout')
@section('title', 'Detail aktivitas')
@section('heading', 'Detail aktivitas')
@section('description', 'Catatan pelaksana dan perubahan yang terjadi pada satu tindakan.')
@section('actions')<a class="btn" href="{{ route('admin.activities.index') }}">Kembali ke riwayat</a>@endsection
@section('content')
<div class="row g-4"><div class="col-lg-5"><section class="card h-100"><div class="card-header"><h2 class="card-title">Informasi tindakan</h2></div><div class="card-body"><dl class="account-details">
    <div><dt>ID aktivitas</dt><dd>#{{ $activity->id }}</dd></div>
    <div><dt>Admin pelaksana</dt><dd>{{ $activity->actor_name }} @if($activity->actor_id)<small class="text-secondary">(#{{ $activity->actor_id }})</small>@else<small class="text-secondary">(akun sudah tidak tersedia)</small>@endif</dd></div>
    <div><dt>Tindakan</dt><dd>{{ \App\Models\AdminActivityLog::EVENTS[$activity->event] ?? $activity->event }}</dd></div>
    <div><dt>Objek</dt><dd>{{ $activity->subject_label }}<small class="d-block text-secondary">{{ $activity->subject_type === 'user' ? 'Pengguna' : 'Kategori' }} #{{ $activity->subject_id }}</small></dd></div>
    <div><dt>Waktu</dt><dd>{{ $activity->created_at->format('d M Y, H:i:s') }} {{ config('app.timezone') }}</dd></div>
    @if($activity->reason)<div><dt>Alasan</dt><dd class="activity-text">{{ $activity->reason }}</dd></div>@endif
</dl></div></section></div>
<div class="col-lg-7"><section class="card"><div class="card-header"><h2 class="card-title">Perubahan data</h2></div>
    @php($fields = array_unique(array_merge(array_keys($activity->before_values ?? []), array_keys($activity->after_values ?? []))))
    @if(count($fields))<div class="table-responsive"><table class="table card-table"><thead><tr><th>Kolom</th><th>Sebelum</th><th>Sesudah</th></tr></thead><tbody>@foreach($fields as $field)<tr><td>{{ ['name' => 'Nama', 'email' => 'Email', 'slug' => 'Slug', 'is_active' => 'Status akun'][$field] ?? $field }}</td>@foreach([$activity->before_values ?? [], $activity->after_values ?? []] as $values)<td class="activity-text">{{ ! array_key_exists($field, $values) ? '—' : (is_bool($values[$field]) ? ($values[$field] ? 'Aktif' : 'Nonaktif') : $values[$field]) }}</td>@endforeach</tr>@endforeach</tbody></table></div>
    @else<div class="card-body"><p class="text-secondary mb-0">Tindakan telah dicatat. Nilai password, hash, dan token tidak disimpan dalam riwayat.</p></div>@endif
</section></div></div>
@endsection
