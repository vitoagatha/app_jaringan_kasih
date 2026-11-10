<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Category;
use Illuminate\Database\QueryException;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;
use Illuminate\View\View;

class CategoryController extends Controller
{
    public function index(Request $request): View
    {
        $filters = $request->validate(['search' => ['nullable', 'string', 'max:100']]);
        $query = Category::query()->withCount('fundings');
        if ($search = trim($filters['search'] ?? '')) {
            $query->where('name', 'ilike', '%'.addcslashes($search, '\\%_').'%');
        }

        return view('admin.categories.index', ['categories' => $query->orderBy('name')->paginate(15)->withQueryString()]);
    }

    public function create(): View
    {
        return view('admin.categories.form', ['category' => new Category]);
    }

    public function edit(Category $category): View
    {
        return view('admin.categories.form', compact('category'));
    }

    public function store(Request $request): RedirectResponse
    {
        return $this->persist($request, new Category);
    }

    public function update(Request $request, Category $category): RedirectResponse
    {
        return $this->persist($request, $category);
    }

    private function persist(Request $request, Category $category): RedirectResponse
    {
        if (is_string($request->input('name'))) {
            $request->merge(['name' => trim($request->input('name'))]);
        }
        $data = $request->validate(['name' => ['required', 'string', 'max:100']]);
        $data['slug'] = Str::slug($data['name']);
        validator($data, ['slug' => ['required', 'max:150', Rule::unique('categories')->ignore($category->id)]], [
            'slug.required' => 'Nama kategori harus mengandung huruf atau angka.',
            'slug.unique' => 'Nama kategori ini sudah digunakan.',
        ])->validate();
        try {
            $category->fill($data)->save();
        } catch (UniqueConstraintViolationException) {
            throw ValidationException::withMessages(['name' => 'Nama kategori ini sudah digunakan.']);
        }

        return redirect()->route('admin.categories.index')->with('status', 'Kategori berhasil disimpan.');
    }

    public function destroy(Category $category): RedirectResponse
    {
        try {
            DB::transaction(function () use ($category) {
                $category = Category::whereKey($category->id)->lockForUpdate()->firstOrFail();
                if ($category->fundings()->exists()) {
                    throw ValidationException::withMessages(['category' => 'Kategori masih digunakan dan tidak dapat dihapus.']);
                }
                $category->delete();
            });
        } catch (QueryException $exception) {
            if ($exception->getCode() !== '23503') {
                throw $exception;
            }
            throw ValidationException::withMessages(['category' => 'Kategori masih digunakan dan tidak dapat dihapus.']);
        }

        return redirect()->route('admin.categories.index')->with('status', 'Kategori berhasil dihapus.');
    }
}
