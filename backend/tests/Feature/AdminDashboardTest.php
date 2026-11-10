<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Funding;
use App\Models\User;
use Illuminate\Auth\Notifications\VerifyEmail;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Notification;
use Tests\PostgresTestCase;

class AdminDashboardTest extends PostgresTestCase
{
    private function admin(): User
    {
        $user = User::factory()->create(['password' => 'AdminBelajar123!']);
        $user->forceFill(['role' => 'admin'])->save();

        return $user;
    }

    public function test_guests_and_api_bearer_tokens_cannot_open_the_admin_panel(): void
    {
        $this->get('/admin')->assertRedirect('/admin/login');
        $admin = $this->admin();
        $this->withToken($admin->createToken('mobile')->plainTextToken)
            ->get('/admin/users')->assertRedirect('/admin/login');
        $this->get('/admin/login')->assertOk()->assertSee('Masuk ke panel admin')->assertHeader('Cache-Control', 'no-store, private');
    }

    public function test_normal_users_cannot_read_or_mutate_admin_resources(): void
    {
        $user = User::factory()->create();
        $category = Category::create(['name' => 'Pendidikan', 'slug' => 'pendidikan']);
        $this->actingAs($user, 'web');
        foreach (['/admin', '/admin/users', '/admin/users/'.$user->id, '/admin/categories', '/admin/categories/create', '/admin/categories/'.$category->id.'/edit', '/admin/profile'] as $path) {
            $this->get($path)->assertForbidden();
        }
        $this->post('/admin/categories', ['name' => 'Baru'])->assertForbidden();
        $this->put('/admin/categories/'.$category->id, ['name' => 'Diubah'])->assertForbidden();
        $this->delete('/admin/categories/'.$category->id)->assertForbidden();
        $this->patch('/admin/profile', ['name' => 'Admin', 'email' => $user->email, 'role' => 'admin'])->assertForbidden();
        $this->put('/admin/profile/password', [])->assertForbidden();
        $this->post('/admin/profile/verification')->assertForbidden();
        $this->assertSame('user', $user->fresh()->role);
        $this->assertDatabaseCount('categories', 1);
    }

    public function test_admin_login_normalizes_email_regenerates_session_and_logout_removes_access(): void
    {
        $admin = $this->admin();
        $this->withSession(['marker' => 'before-login']);
        $oldId = session()->getId();
        $this->post('/admin/login', ['email' => strtoupper($admin->email), 'password' => 'AdminBelajar123!'])
            ->assertRedirect('/admin');
        $this->assertAuthenticatedAs($admin, 'web');
        $this->assertNotSame($oldId, session()->getId());
        $this->get('/admin/login')->assertRedirect('/admin');
        $this->post('/admin/logout')->assertRedirect('/admin/login');
        $this->assertGuest('web');
        $this->get('/admin')->assertRedirect('/admin/login');
    }

    public function test_wrong_password_and_regular_accounts_get_the_same_login_error_without_flashing_password(): void
    {
        $user = User::factory()->create(['password' => 'AdminBelajar123!']);
        $this->from('/admin/login')->post('/admin/login', ['email' => $user->email, 'password' => 'AdminBelajar123!'])
            ->assertRedirect('/admin/login')->assertSessionHasErrors('email')->assertSessionMissing('_old_input.password');
        $this->assertGuest('web');
        $admin = $this->admin();
        $this->post('/admin/login', ['email' => $admin->email, 'password' => 'Salah123!'])->assertSessionHasErrors('email');
        $this->assertGuest('web');
    }

    public function test_admin_login_is_rate_limited(): void
    {
        for ($attempt = 0; $attempt < 5; $attempt++) {
            $this->post('/admin/login', ['email' => 'missing@example.test', 'password' => 'Salah123!'])->assertRedirect();
        }
        $this->post('/admin/login', ['email' => 'missing@example.test', 'password' => 'Salah123!'])->assertStatus(429);
    }

    public function test_login_rejects_passwords_over_the_bcrypt_byte_limit(): void
    {
        $admin = $this->admin();
        $this->post('/admin/login', ['email' => $admin->email, 'password' => str_repeat('á', 37)])
            ->assertSessionHasErrors('password');
        $this->assertGuest('web');
    }

    public function test_public_registration_cannot_assign_admin_role(): void
    {
        $id = $this->postJson('/api/v1/auth/register', [
            'name' => 'Pengguna', 'email' => 'user@example.test', 'password' => 'Belajar123!',
            'password_confirmation' => 'Belajar123!', 'device_name' => 'test', 'role' => 'admin',
        ])->assertCreated()->json('data.user.id');
        $this->assertSame('user', User::findOrFail($id)->role);
        $this->assertFalse(User::findOrFail($id)->isAdmin());
    }

    public function test_dashboard_aggregates_real_users_and_categories_and_excludes_admin_accounts(): void
    {
        $admin = $this->admin();
        User::factory()->count(18)->create();
        User::factory()->unverified()->count(3)->create();
        Category::create(['name' => 'Pendidikan', 'slug' => 'pendidikan']);
        $this->actingAs($admin, 'web')->get('/admin')->assertOk()
            ->assertViewHas('totalUsers', 21)->assertViewHas('verifiedUsers', 18)
            ->assertViewHas('unverifiedUsers', 3)->assertViewHas('totalCategories', 1)
            ->assertViewHas('weeklyTotal', 21)->assertViewHas('recentUsers', fn ($users) => $users->count() === 6 && ! $users->contains('id', $admin->id))
            ->assertViewHas('days', fn ($days) => $days->count() === 7)
            ->assertHeader('Cache-Control', 'no-store, private');
    }

    public function test_empty_dashboard_and_all_admin_pages_render(): void
    {
        $admin = $this->admin();
        $this->actingAs($admin, 'web');
        $this->get('/admin')->assertOk()->assertSee('Belum ada pengguna')->assertViewHas('totalUsers', 0);
        foreach (['/admin/users', '/admin/users/'.$admin->id, '/admin/categories', '/admin/categories/create', '/admin/profile'] as $path) {
            $this->get($path)->assertOk();
        }
    }

    public function test_user_search_verification_role_filters_and_pagination_work_together(): void
    {
        $admin = $this->admin();
        User::factory()->unverified()->count(17)->create(['name' => 'Anggota Komunitas']);
        User::factory()->create(['name' => 'Anggota Terverifikasi']);
        $this->actingAs($admin, 'web')->get('/admin/users?search=Anggota&verification=unverified&role=user&page=2')
            ->assertOk()->assertViewHas('users', fn ($users) => $users->total() === 17 && $users->count() === 2 && $users->currentPage() === 2);
        $this->get('/admin/users?search=%25')->assertOk()->assertViewHas('users', fn ($users) => $users->total() === 0);
        $this->get('/admin/users?role=superadmin')->assertSessionHasErrors('role');
    }

    public function test_user_detail_escapes_names_and_does_not_expose_credentials(): void
    {
        $admin = $this->admin();
        $user = User::factory()->create(['name' => '<script>alert(1)</script>']);
        $this->actingAs($admin, 'web')->get('/admin/users/'.$user->id)->assertOk()
            ->assertSee($user->name)->assertDontSee($user->name, false)->assertDontSee($user->password, false);
    }

    public function test_categories_can_be_created_renamed_and_deleted_and_are_visible_to_the_mobile_api(): void
    {
        $this->actingAs($this->admin(), 'web');
        $this->post('/admin/categories', ['name' => '  Bantuan Sosial  '])->assertRedirect('/admin/categories');
        $category = Category::where('slug', 'bantuan-sosial')->firstOrFail();
        $this->assertSame('Bantuan Sosial', $category->name);
        $this->get('/admin/categories/'.$category->id.'/edit')->assertOk();
        $this->get('/admin/categories?search=Bantuan')->assertViewHas('categories', fn ($items) => $items->total() === 1);
        $this->put('/admin/categories/'.$category->id, ['name' => 'Pendidikan Anak'])->assertRedirect('/admin/categories');
        $this->getJson('/api/v1/categories')->assertOk()->assertJsonFragment(['name' => 'Pendidikan Anak']);
        $this->delete('/admin/categories/'.$category->id)->assertRedirect('/admin/categories');
        $this->assertDatabaseMissing('categories', ['id' => $category->id]);
    }

    public function test_duplicate_and_empty_slugs_are_rejected_and_in_use_categories_cannot_be_deleted(): void
    {
        $admin = $this->admin();
        $category = Category::create(['name' => 'Pendidikan', 'slug' => 'pendidikan']);
        $funding = new Funding(['title' => 'Bantu anak sekolah', 'description' => 'Deskripsi pendanaan untuk pengujian.',
            'target_amount' => 1000000, 'category_id' => $category->id, 'status' => 'draft']);
        $funding->forceFill(['user_id' => $admin->id])->save();
        $this->actingAs($admin, 'web')->post('/admin/categories', ['name' => 'PENDIDIKAN'])->assertSessionHasErrors('slug');
        $this->post('/admin/categories', ['name' => '!!!'])->assertSessionHasErrors('slug');
        $this->post('/admin/categories', ['name' => ' '])->assertSessionHasErrors('name');
        $this->from('/admin/categories')->delete('/admin/categories/'.$category->id)
            ->assertRedirect('/admin/categories')->assertSessionHasErrors('category');
        $this->assertDatabaseHas('categories', ['id' => $category->id]);
        $this->assertDatabaseCount('categories', 1);
    }

    public function test_profile_only_changes_self_and_cannot_edit_roles_or_verify_email(): void
    {
        $admin = $this->admin();
        $other = User::factory()->create();
        $this->actingAs($admin, 'web')->from('/admin/profile')->patch('/admin/profile', [
            'name' => 'Admin Baru', 'email' => $admin->email, 'role' => 'user', 'id' => $other->id,
        ])->assertRedirect('/admin/profile');
        $this->assertSame('admin', $admin->fresh()->role);
        $this->assertSame('Admin Baru', $admin->fresh()->name);
        $this->assertNotSame('Admin Baru', $other->fresh()->name);
    }

    public function test_changing_profile_email_requires_current_password_and_clears_verification(): void
    {
        $admin = $this->admin();
        $data = ['name' => $admin->name, 'email' => 'baru@example.test'];
        $this->actingAs($admin, 'web')->from('/admin/profile')->patch('/admin/profile', $data)
            ->assertSessionHasErrors(['current_password'], errorBag: 'profile');
        $this->assertNotSame('baru@example.test', $admin->fresh()->email);
        $this->patch('/admin/profile', [...$data, 'current_password' => 'AdminBelajar123!'])->assertRedirect('/admin/profile');
        $this->assertSame('baru@example.test', $admin->fresh()->email);
        $this->assertNull($admin->fresh()->email_verified_at);
        $this->assertSame('admin', $admin->fresh()->role);
    }

    public function test_password_change_verifies_old_password_revokes_tokens_and_keeps_current_browser(): void
    {
        $admin = $this->admin();
        $admin->createToken('phone');
        $data = ['current_password' => 'Salah123!', 'password' => 'BaruBelajar123!', 'password_confirmation' => 'BaruBelajar123!'];
        $this->actingAs($admin, 'web')->from('/admin/profile')->put('/admin/profile/password', $data)
            ->assertSessionHasErrors(['current_password'], errorBag: 'password');
        $this->assertSame(1, $admin->tokens()->count());
        $this->put('/admin/profile/password', [...$data, 'current_password' => 'AdminBelajar123!'])->assertRedirect('/admin/profile');
        $this->assertTrue(Hash::check('BaruBelajar123!', $admin->fresh()->password));
        $this->assertSame(0, $admin->tokens()->count());
        $this->get('/admin')->assertOk();
    }

    public function test_stale_password_hash_invalidates_an_admin_web_session(): void
    {
        $this->actingAs($this->admin(), 'web')->withSession(['password_hash_web' => Hash::make('OldPassword123!')]);
        $this->get('/admin')->assertRedirect('/admin/login');
        $this->assertGuest('web');
    }

    public function test_admin_can_send_verification_for_their_own_email(): void
    {
        Notification::fake();
        $admin = $this->admin();
        $admin->forceFill(['email_verified_at' => null])->save();
        $this->actingAs($admin, 'web')->from('/admin/profile')->post('/admin/profile/verification')->assertRedirect('/admin/profile');
        Notification::assertSentTo($admin, VerifyEmail::class);
    }

    public function test_admin_forms_enforce_csrf_outside_the_unit_test_bypass(): void
    {
        $this->actingAs($this->admin(), 'web');
        $this->app->instance('env', 'local');
        $this->post('/admin/categories', ['name' => 'Tidak boleh'])->assertStatus(419);
        $this->post('/admin/logout')->assertStatus(419);
        $this->assertDatabaseCount('categories', 0);
    }

    public function test_admin_creation_command_hashes_password_and_never_promotes_existing_users(): void
    {
        $this->artisan('admin:create', ['email' => 'admin@example.test'])
            ->expectsQuestion('Nama admin', 'Admin Lokal')
            ->expectsQuestion('Password admin (minimal 8 karakter, maksimal 72 byte)', 'AdminBelajar123!')
            ->expectsQuestion('Ulangi password admin', 'AdminBelajar123!')->assertSuccessful();
        $admin = User::where('email', 'admin@example.test')->firstOrFail();
        $this->assertTrue($admin->isAdmin());
        $this->assertTrue(Hash::check('AdminBelajar123!', $admin->password));
        $user = User::factory()->create();
        $this->artisan('admin:create', ['email' => $user->email])->assertFailed();
        $this->assertSame('user', $user->fresh()->role);
    }
}
