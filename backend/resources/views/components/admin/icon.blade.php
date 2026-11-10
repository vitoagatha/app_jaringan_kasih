@props(['name'])
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" {{ $attributes->class(['icon']) }}>
@switch($name)
    @case('home') <path d="m3 10 9-7 9 7v10a1 1 0 0 1-1 1h-5v-7H9v7H4a1 1 0 0 1-1-1Z"/> @break
    @case('users') <circle cx="9" cy="8" r="3"/><path d="M3 21v-3a6 6 0 0 1 12 0v3M16 5a3 3 0 0 1 0 6m5 10v-3a6 6 0 0 0-3-5"/> @break
    @case('category') <rect x="3" y="3" width="7" height="7" rx="2"/><rect x="14" y="3" width="7" height="7" rx="2"/><rect x="3" y="14" width="7" height="7" rx="2"/><rect x="14" y="14" width="7" height="7" rx="2"/> @break
    @case('shield') <path d="m12 3 8 3v6c0 5-8 9-8 9s-8-4-8-9V6Z"/><path d="m8 12 3 3 5-6"/> @break
    @case('arrow') <path d="M5 12h14m-5-5 5 5-5 5"/> @break
    @case('plus') <path d="M12 5v14M5 12h14"/> @break
    @case('search') <circle cx="10" cy="10" r="6"/><path d="m15 15 6 6"/> @break
    @case('logout') <path d="M9 4H4v16h5m4-12 4 4-4 4m-5-4h13"/> @break
    @case('edit') <path d="m15 4 5 5M4 20l5-1L21 7a2 2 0 0 0-5-4L4 15Z"/> @break
    @case('trash') <path d="M3 6h18M9 6V3h6v3M5 6l1 15h12l1-15M10 10v7m4-7v7"/> @break
    @case('check') <path d="m5 12 4 4L19 6"/> @break
    @case('mail') <rect x="3" y="5" width="18" height="14" rx="2"/><path d="m3 6 9 7 9-7"/> @break
    @case('lock') <rect x="5" y="10" width="14" height="11" rx="2"/><path d="M8 10V7a4 4 0 0 1 8 0v3m-4 5v2"/> @break
    @case('menu') <path d="M4 6h16M4 12h16M4 18h16"/> @break
    @case('clock') <circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/> @break
@endswitch
</svg>
