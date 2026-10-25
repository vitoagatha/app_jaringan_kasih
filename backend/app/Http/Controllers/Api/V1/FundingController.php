<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\FundingRequest;
use App\Models\Category;
use App\Models\Funding;
use App\Support\ApiResponse;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use RuntimeException;
use Throwable;

class FundingController extends Controller
{
    public function categories(): JsonResponse
    {
        return ApiResponse::success(['items' => Category::orderBy('name')->get(['id', 'name', 'slug'])]);
    }

    public function index(Request $request): JsonResponse
    {
        return $this->listing($request, Funding::where('status', 'published'));
    }

    public function mine(Request $request): JsonResponse
    {
        return $this->listing($request, Funding::where('user_id', $request->user()->id), true);
    }

    public function wishlist(Request $request): JsonResponse
    {
        $query = Funding::where('status', 'published')->whereIn('id', DB::table('wishlists')
            ->where('user_id', $request->user()->id)->select('funding_id'));

        return $this->listing($request, $query);
    }

    private function listing(Request $request, Builder $query, bool $mine = false): JsonResponse
    {
        $filters = $request->validate([
            'page' => ['sometimes', 'integer', 'min:1', 'max:1000000'],
            'per_page' => ['sometimes', 'integer', 'min:1', 'max:30'],
            'search' => ['sometimes', 'nullable', 'string', 'max:100'],
            'category_id' => ['sometimes', 'integer', 'exists:categories,id'],
            'status' => ['sometimes', 'in:draft,published'],
        ]);
        if (! empty($filters['category_id'])) {
            $query->where('category_id', $filters['category_id']);
        }
        if ($mine && isset($filters['status'])) {
            $query->where('status', $filters['status']);
        }
        $search = trim($filters['search'] ?? '');
        if ($search !== '') {
            // PostgreSQL ILIKE; karakter wildcard diperlakukan sebagai teks literal.
            $query->where('title', 'ilike', '%'.addcslashes($search, '\\%_').'%');
        }
        $page = $query->with(['owner', 'category'])->orderByDesc('created_at')->orderByDesc('id')
            ->paginate($filters['per_page'] ?? 10);
        $userId = Auth::guard('sanctum')->id();
        $saved = $userId ? DB::table('wishlists')->where('user_id', $userId)
            ->whereIn('funding_id', $page->getCollection()->pluck('id'))->pluck('funding_id')->all() : [];

        return ApiResponse::success([
            'items' => $page->getCollection()->map(fn (Funding $funding) => $this->data($funding, in_array($funding->id, $saved, true))),
            'pagination' => ['page' => $page->currentPage(), 'per_page' => $page->perPage(), 'last_page' => $page->lastPage(), 'total' => $page->total()],
        ]);
    }

    public function show(Request $request, Funding $funding): JsonResponse
    {
        abort_unless($funding->status === 'published', 404);

        return $this->detail($funding, Auth::guard('sanctum')->id());
    }

    public function ownShow(Request $request, Funding $funding): JsonResponse
    {
        abort_unless($funding->user_id === $request->user()->id, 404);

        return $this->detail($funding, $request->user()->id);
    }

    public function store(FundingRequest $request): JsonResponse
    {
        $funding = $this->persist($request);

        return ApiResponse::success(['funding' => $this->data($funding->load(['owner', 'category']))], 'Pendanaan dibuat.', 201);
    }

    public function update(FundingRequest $request, Funding $funding): JsonResponse
    {
        $funding = $this->persist($request, $funding);

        return $this->detail($funding, $request->user()->id);
    }

    private function persist(FundingRequest $request, ?Funding $existing = null): Funding
    {
        $path = null;
        if ($request->hasFile('photo')) {
            $path = Storage::disk('public')->putFile('fundings', $request->file('photo'));
            if (! $path) {
                throw new RuntimeException('Funding photo storage failed.');
            }
        }
        try {
            [$funding, $oldPath] = DB::transaction(function () use ($request, $existing, $path) {
                $funding = $existing ? Funding::whereKey($existing->id)->lockForUpdate()->firstOrFail() : new Funding;
                $oldPath = $funding->photo_path;
                $funding->fill($request->safe()->except(['photo', 'remove_photo']));
                if (! $existing) {
                    $funding->user_id = $request->user()->id;
                }
                if ($path !== null || $request->boolean('remove_photo')) {
                    $funding->photo_path = $path;
                }
                $funding->save();

                return [$funding, $oldPath];
            });
        } catch (Throwable $exception) {
            if ($path !== null) {
                Storage::disk('public')->delete($path);
            }
            throw $exception;
        }
        if ($oldPath && $oldPath !== $funding->photo_path) {
            Storage::disk('public')->delete($oldPath);
        }

        return $funding;
    }

    public function saveWishlist(Request $request, Funding $funding): JsonResponse
    {
        abort_unless($funding->status === 'published', 404);
        DB::table('wishlists')->insertOrIgnore([
            'user_id' => $request->user()->id, 'funding_id' => $funding->id,
            'created_at' => now(), 'updated_at' => now(),
        ]);

        return ApiResponse::success(null, 'Ditambahkan ke wishlist.');
    }

    public function removeWishlist(Request $request, string $funding): JsonResponse
    {
        // Tidak membocorkan keberadaan draft lewat perbedaan respons delete.
        validator(['funding' => $funding], ['funding' => ['required', 'integer', 'min:1']])->validate();
        DB::table('wishlists')->where('user_id', $request->user()->id)->where('funding_id', $funding)->delete();

        return ApiResponse::success(null, 'Dihapus dari wishlist.');
    }

    private function detail(Funding $funding, ?int $userId): JsonResponse
    {
        $saved = $userId !== null && DB::table('wishlists')->where('user_id', $userId)->where('funding_id', $funding->id)->exists();

        return ApiResponse::success(['funding' => $this->data($funding->load(['owner', 'category']), $saved)]);
    }

    private function data(Funding $funding, bool $saved = false): array
    {
        return [
            ...$funding->only(['id', 'title', 'description', 'category_id', 'target_amount', 'status', 'created_at', 'updated_at']),
            'raised_amount' => 0, // Transaksi belum diimplementasikan.
            'photo_url' => $funding->photo_path ? '/storage/'.$funding->photo_path : null,
            'owner' => $funding->owner->only(['id', 'name']),
            'category' => $funding->category->only(['id', 'name', 'slug']),
            'is_wishlisted' => $saved,
        ];
    }
}
