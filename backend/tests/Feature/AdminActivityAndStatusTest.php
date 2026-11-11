<?php

namespace Tests\Feature;

use App\Models\AdminActivityLog;
use App\Models\Category;
use App\Models\Funding;
use App\Models\User;
use App\Support\AdminActivity;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use LogicException;
use RuntimeException;
use Tests\PostgresTestCase;

class AdminActivityAndStatusTest extends PostgresTestCase
{
    private function admin(): User
    {
        $admin = User::factory()->create(['password' => 'AdminBelajar123!']);
        $admin->forceFill(['role' => 'admin'])->save();

        return $admin;
    }

    private function statusData(bool $active, int $version = 0): array
    {
        return ['is_active' => $active, 'reason' => 'Hasil pemeriksaan pengelola.', 'status_version' => $version];
    }

    public function test_normal_users_and_guests_cannot_read_logs_or_change_status(): void
    {
        $user = User::factory()->create();
        $log = AdminActivity::record($this->admin(), 'admin.password_changed', $this->admin());
        $this->get('/admin/activities')->assertRedirect('/admin/login');
        $this->patch('/admin/users/'.$user->id.'/status', $this->statusData(false))->assertRedirect('/admin/login');
        $this->actingAs($user, 'web');
        $this->get('/admin/activities')->assertForbidden();
        $this->get('/admin/activities/'.$log->id)->assertForbidden();
        $this->patch('/admin/users/'.$user->id.'/status', $this->statusData(false))->assertForbidden();
        $this->assertTrue($user->fresh()->is_active);
    }

    public function test_status_changes_require_a_reason_and_admin_accounts_are_protected(): void
    {
        $admin = $this->admin();
        $otherAdmin = $this->admin();
        $user = User::factory()->create();
        $this->actingAs($admin, 'web');
        $this->patch('/admin/users/'.$user->id.'/status', [...$this->statusData(false), 'reason' => ' '])->assertSessionHasErrors('reason');
        $this->patch('/admin/users/'.$user->id.'/status', [...$this->statusData(false), 'reason' => str_repeat('a', 1001)])->assertSessionHasErrors('reason');
        $this->patch('/admin/users/'.$user->id.'/status', ['is_active' => false, 'reason' => 'Pemeriksaan'])->assertSessionHasErrors('status_version');
        foreach ([$admin, $otherAdmin] as $target) {
            $this->patch('/admin/users/'.$target->id.'/status', $this->statusData(false))->assertForbidden();
            $this->assertTrue($target->fresh()->is_active);
        }
        $this->assertDatabaseCount('admin_activity_logs', 0);
    }

    public function test_disabling_an_account_expires_tokens_records_the_actor_and_preserves_user_data(): void
    {
        $admin = $this->admin();
        $user = User::factory()->create();
        $category = Category::create(['name' => 'Pendidikan', 'slug' => 'pendidikan']);
        $funding = new Funding(['title' => 'Pendidikan anak', 'description' => 'Deskripsi kegiatan belajar bersama.',
            'category_id' => $category->id, 'target_amount' => 1000000, 'status' => 'published']);
        $funding->forceFill(['user_id' => $user->id])->save();
        DB::table('wishlists')->insert(['user_id' => $user->id, 'funding_id' => $funding->id, 'created_at' => now(), 'updated_at' => now()]);
        $user->createToken('phone', ['*'], now()->addDays(7));
        $user->createToken('other-device');
        $this->actingAs($admin, 'web')->patch('/admin/users/'.$user->id.'/status', $this->statusData(false))
            ->assertRedirect('/admin/users/'.$user->id);
        $user->refresh();
        $this->assertFalse($user->is_active);
        $this->assertSame($admin->id, $user->status_changed_by);
        $this->assertSame(1, $user->status_version);
        $this->assertNotNull($user->status_changed_at);
        $this->assertSame('Hasil pemeriksaan pengelola.', $user->status_reason);
        $this->assertSame(0, $user->tokens()->where(fn ($query) => $query->whereNull('expires_at')->orWhere('expires_at', '>', now()))->count());
        $log = AdminActivityLog::sole();
        $this->assertSame('user.deactivated', $log->event);
        $this->assertSame($admin->id, $log->actor_id);
        $this->assertSame(['is_active' => true], $log->before_values);
        $this->assertSame(['is_active' => false], $log->after_values);
        $this->assertDatabaseHas('fundings', ['id' => $funding->id, 'status' => 'published']);
        $this->assertDatabaseHas('wishlists', ['user_id' => $user->id, 'funding_id' => $funding->id]);
    }

    public function test_disabled_accounts_cannot_login_or_access_any_protected_api_with_an_old_token(): void
    {
        $admin = $this->admin();
        $user = User::factory()->create(['password' => 'Belajar123!']);
        $token = $user->createToken('phone', ['*'], now()->addDays(7))->plainTextToken;
        $this->actingAs($admin, 'web')->patch('/admin/users/'.$user->id.'/status', $this->statusData(false))->assertRedirect();
        $this->app['auth']->forgetGuards();
        $this->postJson('/api/v1/auth/login', ['email' => $user->email, 'password' => 'Salah123!', 'device_name' => 'test'])
            ->assertUnauthorized()->assertJsonMissingPath('code');
        $this->postJson('/api/v1/auth/login', ['email' => $user->email, 'password' => 'Belajar123!', 'device_name' => 'test'])
            ->assertForbidden()->assertJsonPath('code', 'account_disabled');
        foreach ([['GET', 'auth/me'], ['POST', 'auth/logout'], ['PATCH', 'auth/profile'], ['POST', 'auth/change-password'],
            ['POST', 'auth/email/verification-notification'], ['POST', 'auth/profile/photo'], ['DELETE', 'auth/profile/photo'],
            ['GET', 'me/fundings'], ['GET', 'me/wishlist'], ['POST', 'fundings'], ['PATCH', 'fundings/1'],
            ['PUT', 'fundings/1/wishlist'], ['DELETE', 'fundings/1/wishlist']] as [$method, $path]) {
            $this->app['auth']->forgetGuards();
            $this->withToken($token)->json($method, '/api/v1/'.$path)->assertForbidden()->assertJsonPath('code', 'account_disabled');
        }
        $this->getJson('/api/v1/health')->assertOk();
        $this->getJson('/api/v1/categories')->assertOk();
    }

    public function test_reactivation_allows_new_login_but_does_not_revive_old_tokens_and_rejects_stale_forms(): void
    {
        $this->travelTo(now()->startOfSecond());
        $admin = $this->admin();
        $user = User::factory()->create(['password' => 'Belajar123!']);
        $oldToken = $user->createToken('phone')->plainTextToken;
        $boundaryToken = $user->createToken('exact-expiry', ['*'], now())->plainTextToken;
        $this->actingAs($admin, 'web');
        $this->patch('/admin/users/'.$user->id.'/status', $this->statusData(false))->assertRedirect();
        $this->patch('/admin/users/'.$user->id.'/status', [...$this->statusData(true, 1), 'reason' => 'Pemeriksaan selesai.'])->assertRedirect();
        $this->patch('/admin/users/'.$user->id.'/status', $this->statusData(false))->assertSessionHasErrors('status');
        $this->assertTrue($user->fresh()->is_active);
        $this->assertSame(2, $user->fresh()->status_version);
        $this->assertDatabaseCount('admin_activity_logs', 2);
        $this->app['auth']->forgetGuards();
        $this->withToken($oldToken)->getJson('/api/v1/auth/me')->assertUnauthorized();
        $this->app['auth']->forgetGuards();
        $this->withToken($boundaryToken)->getJson('/api/v1/auth/me')->assertUnauthorized();
        $this->app['auth']->forgetGuards();
        $newToken = $this->postJson('/api/v1/auth/login', ['email' => $user->email, 'password' => 'Belajar123!', 'device_name' => 'test'])
            ->assertOk()->json('data.token');
        $this->app['auth']->forgetGuards();
        $this->withToken($newToken)->getJson('/api/v1/auth/me')->assertOk();
    }

    public function test_registration_and_mobile_profile_cannot_change_their_own_status_or_role(): void
    {
        $response = $this->postJson('/api/v1/auth/register', ['name' => 'Pengguna', 'email' => 'status@example.test',
            'password' => 'Belajar123!', 'password_confirmation' => 'Belajar123!', 'device_name' => 'test', 'is_active' => false, 'role' => 'admin']);
        $response->assertCreated();
        $user = User::findOrFail($response->json('data.user.id'));
        $this->assertTrue($user->is_active);
        $this->assertSame('user', $user->role);
        $this->withToken($response->json('data.token'))->patchJson('/api/v1/auth/profile', ['name' => 'Nama baru', 'email' => $user->email,
            'role' => 'admin', 'is_active' => false, 'status_version' => 99])->assertOk();
        $this->assertTrue($user->fresh()->is_active);
        $this->assertSame(0, $user->fresh()->status_version);
        $this->assertDatabaseCount('admin_activity_logs', 0);
    }

    public function test_failure_to_record_activity_rolls_back_the_status_change_and_token_expiry(): void
    {
        $admin = $this->admin();
        $user = User::factory()->create();
        $token = $user->createToken('phone');
        $fail = true;
        AdminActivityLog::creating(function () use (&$fail) {
            if ($fail) {
                throw new RuntimeException('Simulated audit storage failure');
            }
        });
        try {
            $this->actingAs($admin, 'web')->patch('/admin/users/'.$user->id.'/status', $this->statusData(false))->assertServerError();
            $this->assertTrue($user->fresh()->is_active);
            $this->assertSame(0, $user->fresh()->status_version);
            $this->assertNull($token->accessToken->fresh()->expires_at);
            $this->assertDatabaseCount('admin_activity_logs', 0);
        } finally {
            $fail = false;
        }
    }

    public function test_resetting_a_password_does_not_reactivate_a_disabled_account(): void
    {
        $user = User::factory()->create();
        $this->actingAs($this->admin(), 'web')->patch('/admin/users/'.$user->id.'/status', $this->statusData(false))->assertRedirect();
        $this->app['auth']->forgetGuards();
        $token = Password::createToken($user->fresh());
        $this->postJson('/api/v1/auth/reset-password', ['email' => $user->email, 'token' => $token,
            'password' => 'ResetBelajar123!', 'password_confirmation' => 'ResetBelajar123!'])->assertOk();
        $this->assertFalse($user->fresh()->is_active);
        $this->postJson('/api/v1/auth/login', ['email' => $user->email, 'password' => 'ResetBelajar123!', 'device_name' => 'test'])
            ->assertForbidden()->assertJsonPath('code', 'account_disabled');
    }

    public function test_category_creation_update_and_deletion_keep_snapshots_after_deletion_and_ignore_no_op_edits(): void
    {
        $this->actingAs($this->admin(), 'web');
        $this->post('/admin/categories', ['name' => 'Bantuan Sosial'])->assertRedirect();
        $category = Category::sole();
        $this->put('/admin/categories/'.$category->id, ['name' => 'Bantuan Sosial'])->assertRedirect();
        $this->assertDatabaseCount('admin_activity_logs', 1);
        $this->put('/admin/categories/'.$category->id, ['name' => 'Pendidikan Anak'])->assertRedirect();
        $this->delete('/admin/categories/'.$category->id)->assertRedirect();
        $this->assertDatabaseMissing('categories', ['id' => $category->id]);
        $this->assertSame(['category.created', 'category.updated', 'category.deleted'], AdminActivityLog::orderBy('id')->pluck('event')->all());
        $log = AdminActivityLog::where('event', 'category.deleted')->sole();
        $this->assertSame('Pendidikan Anak', $log->subject_label);
        $this->assertSame(['name' => 'Pendidikan Anak', 'slug' => 'pendidikan-anak'], $log->before_values);
        $this->get('/admin/activities/'.$log->id)->assertOk()->assertSee('Pendidikan Anak');
    }

    public function test_profile_and_password_activity_do_not_record_secrets_and_log_only_changed_fields(): void
    {
        $admin = $this->admin();
        $this->actingAs($admin, 'web')->patch('/admin/profile', ['name' => 'Nama Admin Baru', 'email' => $admin->email])->assertRedirect();
        $log = AdminActivityLog::sole();
        $this->assertSame('admin.profile_updated', $log->event);
        $this->assertSame(['name' => 'Nama Admin Baru'], $log->after_values);
        $this->put('/admin/profile/password', ['current_password' => 'AdminBelajar123!', 'password' => 'BaruBelajar123!',
            'password_confirmation' => 'BaruBelajar123!'])->assertRedirect();
        $passwordLog = AdminActivityLog::where('event', 'admin.password_changed')->sole();
        $this->assertNull($passwordLog->before_values);
        $this->assertNull($passwordLog->after_values);
        $this->assertStringNotContainsString('BaruBelajar123!', $passwordLog->toJson());
        $this->assertStringNotContainsString($admin->fresh()->password, $passwordLog->toJson());
        $this->assertTrue(Hash::check('BaruBelajar123!', $admin->fresh()->password));
    }

    public function test_log_recorder_whitelists_fields_and_ignores_injected_secrets(): void
    {
        $admin = $this->admin();
        $category = Category::create(['name' => 'Pendidikan', 'slug' => 'pendidikan']);
        $log = AdminActivity::record($admin, 'category.updated', $category,
            ['name' => 'Lama', 'password' => 'secret', 'token' => 'secret'], ['name' => 'Baru', 'remember_token' => 'secret']);
        $this->assertSame(['name' => 'Lama'], $log->before_values);
        $this->assertSame(['name' => 'Baru'], $log->after_values);
        $this->assertStringNotContainsString('secret', $log->toJson());
    }

    public function test_activity_filters_dates_pagination_and_subject_filter_work(): void
    {
        $admin = $this->admin();
        $user = User::factory()->create();
        $this->travelTo(now()->startOfDay()->addHours(12));
        for ($index = 0; $index < 23; $index++) {
            AdminActivity::record($admin, 'user.deactivated', $user, ['is_active' => true], ['is_active' => false], 'Pengujian filter');
        }
        $this->actingAs($admin, 'web')->get('/admin/activities?'.http_build_query(['actor_id' => $admin->id, 'event' => 'user.deactivated',
            'date_from' => now()->toDateString(), 'date_to' => now()->toDateString(), 'subject_type' => 'user', 'subject_id' => $user->id, 'page' => 2]))
            ->assertOk()->assertViewHas('activities', fn ($logs) => $logs->total() === 23 && $logs->count() === 3);
        $this->get('/admin/activities?date_to='.now()->subDay()->toDateString())->assertOk()->assertViewHas('activities', fn ($logs) => $logs->total() === 0);
        $this->get('/admin/activities?date_from=2026-11-11&date_to=2026-11-10')->assertSessionHasErrors('date_to');
        $this->get('/admin/activities?event=unknown')->assertSessionHasErrors('event');
        $this->get('/admin/activities?subject_id=1')->assertSessionHasErrors('subject_type');
    }

    public function test_status_filter_and_detail_render_and_escape_reasons(): void
    {
        $admin = $this->admin();
        $user = User::factory()->create();
        $reason = '<script>alert(1)</script>';
        $this->actingAs($admin, 'web')->patch('/admin/users/'.$user->id.'/status', [...$this->statusData(false), 'reason' => $reason])->assertRedirect();
        $this->get('/admin/users?status=inactive')->assertOk()->assertViewHas('users', fn ($users) => $users->total() === 1);
        $this->get('/admin/users/'.$user->id)->assertOk()->assertSee('Aktifkan kembali')->assertSee($reason)->assertDontSee($reason, false);
        $this->get('/admin/activities/'.AdminActivityLog::sole()->id)->assertOk()->assertSee($reason)->assertDontSee($reason, false);
        $this->get('/admin/users/'.$admin->id)->assertOk()->assertDontSee('id="user-status-form"', false);
    }

    public function test_activity_has_no_update_or_delete_routes_and_model_rejects_mutation(): void
    {
        $admin = $this->admin();
        $log = AdminActivity::record($admin, 'admin.password_changed', $admin);
        $this->actingAs($admin, 'web');
        $this->patch('/admin/activities/'.$log->id, ['reason' => 'tamper'])->assertStatus(405);
        $this->delete('/admin/activities/'.$log->id)->assertStatus(405);
        try {
            $log->forceFill(['actor_name' => 'Changed'])->save();
            $this->fail('Activity update was allowed.');
        } catch (LogicException) {
            $this->assertSame($admin->name, $log->fresh()->actor_name);
        }
        $this->expectException(LogicException::class);
        $log->delete();
    }

    public function test_database_rejects_an_inactive_admin_account(): void
    {
        $admin = $this->admin();
        $this->expectException(QueryException::class);
        $admin->forceFill(['is_active' => false])->save();
    }
}
