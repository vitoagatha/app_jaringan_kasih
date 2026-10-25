<?php

namespace App\Http\Requests;

use App\Support\PhotoRules;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class FundingRequest extends FormRequest
{
    public function authorize(): bool
    {
        $funding = $this->route('funding');

        return $this->user() !== null && ($funding === null || $funding->user_id === $this->user()->id);
    }

    public function rules(): array
    {
        return [
            'title' => ['required', 'string', 'max:150'],
            'description' => ['required', 'string', 'min:20', 'max:10000'],
            'category_id' => ['required', 'integer', 'exists:categories,id'],
            'target_amount' => ['required', 'integer', 'min:1', 'max:1000000000000'],
            'status' => ['required', Rule::in(['draft', 'published'])],
            'photo' => PhotoRules::rules(),
            'remove_photo' => ['sometimes', 'boolean'],
        ];
    }

    public function messages(): array
    {
        return [...PhotoRules::messages(),
            'required' => ':attribute wajib diisi.',
            'string' => ':attribute harus berupa teks.',
            'integer' => ':attribute harus berupa bilangan bulat.',
            'title.max' => 'Judul maksimal 150 karakter.',
            'description.min' => 'Deskripsi minimal 20 karakter.',
            'description.max' => 'Deskripsi maksimal 10000 karakter.',
            'category_id.exists' => 'Kategori tidak tersedia.',
            'target_amount.min' => 'Target dana minimal Rp1.',
            'target_amount.max' => 'Target dana maksimal Rp1.000.000.000.000.',
            'status.in' => 'Status harus draft atau published.',
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator) {
            if ($this->hasFile('photo') && $this->boolean('remove_photo')) {
                $validator->errors()->add('photo', 'Pilih unggah foto baru atau hapus foto, bukan keduanya.');
            }
        });
    }
}
