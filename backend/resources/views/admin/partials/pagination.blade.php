@if($paginator->hasPages())
<nav class="card-footer d-flex flex-wrap align-items-center justify-content-between gap-3" aria-label="Halaman daftar">
    <span class="text-secondary small">{{ $paginator->firstItem() }}–{{ $paginator->lastItem() }} dari {{ $paginator->total() }} data · Halaman {{ $paginator->currentPage() }}/{{ $paginator->lastPage() }}</span>
    <div class="d-flex gap-2">@if($paginator->onFirstPage())<span class="btn btn-sm disabled" aria-disabled="true">Sebelumnya</span>@else<a class="btn btn-sm" href="{{ $paginator->previousPageUrl() }}" rel="prev">Sebelumnya</a>@endif @if($paginator->hasMorePages())<a class="btn btn-sm" href="{{ $paginator->nextPageUrl() }}" rel="next">Berikutnya</a>@else<span class="btn btn-sm disabled" aria-disabled="true">Berikutnya</span>@endif</div>
</nav>
@endif
