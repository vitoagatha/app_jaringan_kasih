<?php

namespace App\Support;

final class PhotoRules
{
    public static function rules(bool $required = false): array
    {
        return [$required ? 'required' : 'nullable', 'file', 'image', 'mimes:jpg,jpeg,png,webp',
            'max:2048', 'dimensions:min_width=32,min_height=32,max_width=4096,max_height=4096'];
    }

    public static function messages(): array
    {
        return [
            'photo.required' => 'Pilih foto terlebih dahulu.',
            'photo.uploaded' => 'Unggah gagal. Periksa ukuran file dan coba lagi.',
            'photo.file' => 'Foto harus berupa file.',
            'photo.image' => 'File harus berupa gambar yang valid.',
            'photo.mimes' => 'Gunakan JPEG, PNG, atau WebP.',
            'photo.max' => 'Foto maksimal 2 MB.',
            'photo.dimensions' => 'Dimensi foto harus antara 32 dan 4096 piksel pada setiap sisi.',
        ];
    }
}
