<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Funding;
use App\Models\User;
use Database\Seeders\CategorySeeder;
use Illuminate\Database\QueryException;
use Tests\PostgresTestCase;

class FundingTest extends PostgresTestCase
{
    private function data(array $overrides = []): array
    {
        return array_replace(['title' => 'Bantu pendidikan anak', 'description' => 'Deskripsi pendanaan yang cukup panjang untuk pengujian.',
            'target_amount' => 1000000, 'category_id' => Category::firstOrFail()->id, 'status' => 'draft'], $overrides);
    }

    private function login(User $user): void
    {
        $this->app['auth']->forgetGuards();
        $this->withToken($user->createToken('test')->plainTextToken);
    }

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(CategorySeeder::class);
    }

    public function test_categories_come_from_database_and_writes_require_auth(): void
    {
        $this->getJson('/api/v1/categories')->assertOk()->assertJsonCount(6, 'data.items');
        $this->postJson('/api/v1/fundings', $this->data())->assertUnauthorized();
        $this->getJson('/api/v1/me/fundings')->assertUnauthorized();
        $this->getJson('/api/v1/me/wishlist')->assertUnauthorized();
    }

    public function test_create_draft_does_not_trust_owner_or_raised_amount_from_client(): void
    {
        $user = User::factory()->create();
        $other = User::factory()->create();
        $this->login($user);
        $id = $this->postJson('/api/v1/fundings', $this->data(['user_id' => $other->id, 'raised_amount' => 999]))
            ->assertCreated()->assertJsonPath('data.funding.owner.id', $user->id)
            ->assertJsonPath('data.funding.raised_amount', 0)->assertJsonMissingPath('data.funding.owner.email')
            ->json('data.funding.id');
        $this->getJson('/api/v1/fundings')->assertJsonCount(0, 'data.items');
        $this->getJson('/api/v1/fundings/'.$id)->assertNotFound();
        $this->getJson('/api/v1/me/fundings/'.$id)->assertOk();
        $this->getJson('/api/v1/me/fundings')->assertJsonCount(1, 'data.items');
    }

    public function test_only_owner_can_edit_and_view_draft_then_publish_it(): void
    {
        $owner = User::factory()->create();
        $funding = $this->funding($owner);
        $this->login(User::factory()->create());
        $this->getJson('/api/v1/me/fundings/'.$funding->id)->assertNotFound();
        $this->patchJson('/api/v1/fundings/'.$funding->id, $this->data(['status' => 'published']))->assertForbidden();
        $this->login($owner);
        $this->patchJson('/api/v1/fundings/'.$funding->id, $this->data(['title' => 'Judul diterbitkan', 'status' => 'published']))
            ->assertOk()->assertJsonPath('data.funding.title', 'Judul diterbitkan');
        $this->getJson('/api/v1/fundings/'.$funding->id)->assertOk();
        $this->getJson('/api/v1/me/fundings?status=draft')->assertJsonCount(0, 'data.items');
    }

    private function funding(User $owner, array $changes = []): Funding
    {
        $funding = new Funding($this->data($changes));
        $funding->user_id = $owner->id;
        $funding->save();

        return $funding;
    }

    public function test_pagination_search_and_category_filter_are_combined_and_latest_is_stable(): void
    {
        $owner = User::factory()->create();
        $category = Category::where('id', '!=', Category::first()->id)->first();
        $first = $this->funding($owner, ['title' => 'Sekolah pertama', 'status' => 'published']);
        $second = $this->funding($owner, ['title' => 'SEKOLAH kedua', 'status' => 'published']);
        $this->funding($owner, ['title' => 'Sekolah kategori lain', 'category_id' => $category->id, 'status' => 'published']);
        $this->funding($owner, ['title' => 'Sekolah rahasia']);
        $url = '/api/v1/fundings?search=sekolah&category_id='.$first->category_id.'&per_page=1';
        $this->getJson($url)->assertOk()->assertJsonPath('data.pagination.total', 2)
            ->assertJsonPath('data.pagination.last_page', 2)->assertJsonPath('data.items.0.id', $second->id);
        $this->getJson($url.'&page=2')->assertJsonPath('data.items.0.id', $first->id);
        $this->getJson($url.'&page=3')->assertJsonCount(0, 'data.items');
    }

    public function test_wildcards_are_literal_and_invalid_filter_is_422(): void
    {
        $owner = User::factory()->create();
        $this->funding($owner, ['title' => 'Target 100% tercapai', 'status' => 'published']);
        $this->funding($owner, ['title' => 'Judul biasa', 'status' => 'published']);
        $this->getJson('/api/v1/fundings?search=%25')->assertJsonCount(1, 'data.items');
        $this->getJson('/api/v1/fundings?per_page=999')->assertUnprocessable();
        $this->getJson('/api/v1/fundings?category_id=999999')->assertUnprocessable();
        $this->getJson('/api/v1/fundings?page=-1')->assertUnprocessable();
    }

    public function test_invalid_funding_fields_are_rejected(): void
    {
        $this->login(User::factory()->create());
        $this->postJson('/api/v1/fundings', $this->data(['title' => '', 'description' => 'short',
            'category_id' => -1, 'target_amount' => 1.5, 'status' => 'approved']))
            ->assertUnprocessable()->assertJsonValidationErrors(['title', 'description', 'category_id', 'target_amount', 'status']);
        $this->assertDatabaseCount('fundings', 0);
    }

    public function test_wishlist_is_isolated_idempotent_and_hides_unpublished_fundings(): void
    {
        $owner = User::factory()->create();
        $user = User::factory()->create();
        $funding = $this->funding($owner, ['status' => 'published']);
        $this->login($user);
        $url = '/api/v1/fundings/'.$funding->id.'/wishlist';
        $this->putJson($url)->assertOk();
        $this->putJson($url)->assertOk();
        $this->assertDatabaseCount('wishlists', 1);
        $this->getJson('/api/v1/fundings')->assertJsonPath('data.items.0.is_wishlisted', true);
        $this->getJson('/api/v1/me/wishlist')->assertJsonCount(1, 'data.items');
        $this->login($owner);
        $this->getJson('/api/v1/me/wishlist')->assertJsonCount(0, 'data.items');
        $funding->update(['status' => 'draft']);
        $this->login($user);
        $this->getJson('/api/v1/me/wishlist')->assertJsonCount(0, 'data.items');
        $this->putJson($url)->assertNotFound();
        $this->deleteJson($url)->assertOk();
        $this->deleteJson($url)->assertOk();
        $this->deleteJson('/api/v1/fundings/999999/wishlist')->assertOk();
        $this->assertDatabaseCount('wishlists', 0);
    }

    public function test_database_rejects_invalid_target_even_without_http_validation(): void
    {
        $this->expectException(QueryException::class);
        $this->funding(User::factory()->create(), ['target_amount' => -1]);
    }
}
