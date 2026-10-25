<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\PostgresTestCase;

class ProfilePhotoTest extends PostgresTestCase
{
    private function png(int $width = 32, int $height = 32): UploadedFile
    {
        // PNG asli, tanpa membutuhkan ekstensi GD hanya untuk membuat fixture.
        $chunk = fn ($type, $bytes) => pack('N', strlen($bytes)).$type.$bytes.pack('N', crc32($type.$bytes));
        $contents = "\x89PNG\r\n\x1a\n"
            .$chunk('IHDR', pack('NNCCCCC', $width, $height, 8, 2, 0, 0, 0))
            .$chunk('IDAT', gzcompress(str_repeat("\0".str_repeat("\0", $width * 3), $height)))
            .$chunk('IEND', '');

        return UploadedFile::fake()->createWithContent('profile.png', $contents);
    }

    private function account(): User
    {
        Storage::fake('public');
        $user = User::factory()->create();
        $this->withToken($user->createToken('test')->plainTextToken);

        return $user;
    }

    public function test_photo_upload_replacement_and_delete_keep_database_and_files_consistent(): void
    {
        $user = $this->account();
        $other = User::factory()->create(['photo_path' => 'avatars/other.png']);
        Storage::disk('public')->put('avatars/other.png', 'unrelated');
        $this->postJson('/api/v1/auth/profile/photo', ['photo' => $this->png()])->assertOk();
        $old = $user->fresh()->photo_path;
        Storage::disk('public')->assertExists($old);
        $this->postJson('/api/v1/auth/profile/photo', ['photo' => $this->png()])->assertOk()
            ->assertJsonPath('data.user.photo_url', fn ($value) => str_starts_with($value, '/storage/avatars/'));
        $new = $user->fresh()->photo_path;
        $this->assertNotSame($old, $new);
        Storage::disk('public')->assertMissing($old);
        Storage::disk('public')->assertExists($new);
        $this->deleteJson('/api/v1/auth/profile/photo')->assertOk()->assertJsonPath('data.user.photo_url', null);
        Storage::disk('public')->assertMissing($new);
        Storage::disk('public')->assertExists('avatars/other.png');
        $this->assertSame('avatars/other.png', $other->fresh()->photo_path);
        $this->deleteJson('/api/v1/auth/profile/photo')->assertOk();
    }

    public function test_spoofed_extension_svg_oversize_and_small_dimensions_are_rejected(): void
    {
        $this->account();
        foreach ([
            UploadedFile::fake()->createWithContent('fake.jpg', '<?php echo "unsafe";'),
            UploadedFile::fake()->createWithContent('image.svg', '<svg xmlns="http://www.w3.org/2000/svg"></svg>'),
            $this->png()->size(2049),
            $this->png(16, 16),
            $this->png(4097, 32),
        ] as $file) {
            $this->postJson('/api/v1/auth/profile/photo', ['photo' => $file])->assertUnprocessable()->assertJsonValidationErrors(['photo']);
        }
        $this->assertSame([], Storage::disk('public')->allFiles());
    }

    public function test_photo_routes_require_authentication(): void
    {
        $this->postJson('/api/v1/auth/profile/photo')->assertUnauthorized();
        $this->deleteJson('/api/v1/auth/profile/photo')->assertUnauthorized();
    }
}
