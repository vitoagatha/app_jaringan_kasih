<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Funding;
use App\Models\User;
use Database\Seeders\CategorySeeder;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use RuntimeException;
use Tests\PostgresTestCase;

class FundingPhotoTest extends PostgresTestCase
{
    private User $owner;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('public');
        $this->seed(CategorySeeder::class);
        $this->owner = User::factory()->create();
        $this->withToken($this->owner->createToken('test')->plainTextToken);
    }

    private function data(array $changes = []): array
    {
        return array_replace(['title' => 'Pendanaan bergambar', 'description' => 'Deskripsi pendanaan yang cukup panjang untuk diuji.',
            'category_id' => Category::firstOrFail()->id, 'target_amount' => 500000, 'status' => 'published'], $changes);
    }

    private function image(): UploadedFile
    {
        $chunk = fn ($type, $bytes) => pack('N', strlen($bytes)).$type.$bytes.pack('N', crc32($type.$bytes));
        $png = "\x89PNG\r\n\x1a\n".$chunk('IHDR', pack('NNCCCCC', 32, 32, 8, 2, 0, 0, 0))
            .$chunk('IDAT', gzcompress(str_repeat("\0".str_repeat("\0", 96), 32))).$chunk('IEND', '');

        return UploadedFile::fake()->createWithContent('cover.png', $png);
    }

    public function test_create_with_photo_returns_relative_storage_url_on_list_detail_and_wishlist(): void
    {
        $response = $this->post('/api/v1/fundings', $this->data(['photo' => $this->image()]))->assertCreated();
        $funding = Funding::findOrFail($response->json('data.funding.id'));
        $url = '/storage/'.$funding->photo_path;
        $this->assertStringStartsWith('fundings/', $funding->photo_path);
        Storage::disk('public')->assertExists($funding->photo_path);
        $response->assertJsonPath('data.funding.photo_url', $url)->assertJsonMissingPath('data.funding.photo_path');
        $this->getJson('/api/v1/fundings')->assertJsonPath('data.items.0.photo_url', $url);
        $this->getJson('/api/v1/fundings/'.$funding->id)->assertJsonPath('data.funding.photo_url', $url);
        $this->putJson('/api/v1/fundings/'.$funding->id.'/wishlist')->assertOk();
        $this->getJson('/api/v1/me/wishlist')->assertJsonPath('data.items.0.photo_url', $url);
    }

    public function test_edit_replaces_then_removes_photo_and_cleans_old_files(): void
    {
        $id = $this->post('/api/v1/fundings', $this->data(['photo' => $this->image()]))->json('data.funding.id');
        $funding = Funding::findOrFail($id);
        $old = $funding->photo_path;
        $this->post('/api/v1/fundings/'.$id, $this->data(['_method' => 'PATCH', 'photo' => $this->image()]))->assertOk();
        $new = $funding->fresh()->photo_path;
        $this->assertNotSame($old, $new);
        Storage::disk('public')->assertMissing($old);
        Storage::disk('public')->assertExists($new);
        $this->patchJson('/api/v1/fundings/'.$id, $this->data(['title' => 'Judul berubah']))
            ->assertOk()->assertJsonPath('data.funding.photo_url', '/storage/'.$new);
        $this->patchJson('/api/v1/fundings/'.$id, $this->data(['remove_photo' => true]))
            ->assertOk()->assertJsonPath('data.funding.photo_url', null);
        Storage::disk('public')->assertMissing($new);
    }

    public function test_non_owner_cannot_change_or_remove_photo(): void
    {
        $id = $this->post('/api/v1/fundings', $this->data(['photo' => $this->image()]))->json('data.funding.id');
        $original = Funding::findOrFail($id)->photo_path;
        $this->app['auth']->forgetGuards();
        $this->withToken(User::factory()->create()->createToken('other')->plainTextToken);
        $this->post('/api/v1/fundings/'.$id, $this->data(['_method' => 'PATCH', 'photo' => $this->image()]))->assertForbidden();
        $this->patchJson('/api/v1/fundings/'.$id, $this->data(['remove_photo' => true]))->assertForbidden();
        $this->assertSame($original, Funding::findOrFail($id)->photo_path);
        $this->assertCount(1, Storage::disk('public')->allFiles());
    }

    public function test_invalid_and_oversized_photo_do_not_create_a_funding(): void
    {
        foreach ([UploadedFile::fake()->createWithContent('fake.jpg', '<?php echo "unsafe";'), $this->image()->size(2049)] as $file) {
            $this->post('/api/v1/fundings', $this->data(['photo' => $file]))->assertUnprocessable()->assertJsonValidationErrors(['photo']);
        }
        $this->assertDatabaseCount('fundings', 0);
        $this->assertSame([], Storage::disk('public')->allFiles());
    }

    public function test_failed_database_save_removes_newly_uploaded_file(): void
    {
        Funding::creating(fn () => throw new RuntimeException('Simulated database write failure'));
        try {
            $this->post('/api/v1/fundings', $this->data(['photo' => $this->image()]))->assertStatus(500);
            $this->assertDatabaseCount('fundings', 0);
            $this->assertSame([], Storage::disk('public')->allFiles());
        } finally {
            Funding::flushEventListeners();
        }
    }

    public function test_failed_replacement_keeps_original_photo_and_data(): void
    {
        $id = $this->post('/api/v1/fundings', $this->data(['photo' => $this->image()]))->json('data.funding.id');
        $original = Funding::findOrFail($id)->photo_path;
        Funding::updating(fn () => throw new RuntimeException('Simulated update failure'));
        try {
            $this->post('/api/v1/fundings/'.$id, $this->data([
                '_method' => 'PATCH', 'title' => 'Judul yang gagal disimpan', 'photo' => $this->image(),
            ]))->assertStatus(500);
            $this->assertSame($original, Funding::findOrFail($id)->photo_path);
            $this->assertSame('Pendanaan bergambar', Funding::findOrFail($id)->title);
            $this->assertSame([$original], Storage::disk('public')->allFiles());
        } finally {
            Funding::flushEventListeners();
        }
    }

    public function test_existing_fundings_and_forged_paths_are_safe(): void
    {
        $this->postJson('/api/v1/fundings', $this->data(['photo_path' => 'arbitrary/file.png', 'photo_url' => 'https://other.example/image']))
            ->assertCreated()->assertJsonPath('data.funding.photo_url', null);
        $this->post('/api/v1/fundings', $this->data(['photo' => $this->image(), 'remove_photo' => '1']))
            ->assertUnprocessable()->assertJsonValidationErrors(['photo']);
        $this->assertDatabaseCount('fundings', 1);
    }
}
