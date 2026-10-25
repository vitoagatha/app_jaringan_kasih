<?php

namespace Tests\Feature;

use App\Models\User;
use App\Notifications\ResetPasswordToken;
use Illuminate\Auth\Notifications\VerifyEmail;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Facades\URL;
use Tests\PostgresTestCase;

class AccountTest extends PostgresTestCase
{
    private function loginUser(): User
    {
        $user = User::factory()->create(['password' => 'old-password']);
        $this->withToken($user->createToken('test')->plainTextToken);

        return $user;
    }

    public function test_profile_update_only_accepts_safe_fields_and_preserves_verification(): void
    {
        $user = $this->loginUser();
        $this->patchJson('/api/v1/auth/profile', [
            'name' => 'Nama Baru', 'email' => strtoupper($user->email),
            'email_verified_at' => null, 'photo_path' => 'unsafe', 'password' => 'injected',
        ])->assertOk()->assertJsonPath('data.user.name', 'Nama Baru')
            ->assertJsonPath('data.user.photo_url', null);
        $this->assertNotNull($user->fresh()->email_verified_at);
        $this->assertNull($user->fresh()->photo_path);
        $this->assertTrue(Hash::check('old-password', $user->fresh()->password));
    }

    public function test_email_change_requires_password_and_clears_verification_and_reset_tokens(): void
    {
        $user = $this->loginUser();
        $user->createToken('other device');
        Password::createToken($user);
        $this->patchJson('/api/v1/auth/profile', ['name' => 'Nama', 'email' => 'new@example.test'])
            ->assertUnprocessable()->assertJsonValidationErrors(['current_password']);
        $this->patchJson('/api/v1/auth/profile', [
            'name' => 'Nama', 'email' => 'NEW@example.test', 'current_password' => 'old-password',
        ])->assertOk()->assertJsonPath('data.user.email', 'new@example.test')
            ->assertJsonPath('data.user.email_verified_at', null);
        $this->assertDatabaseCount('password_reset_tokens', 0);
        $this->assertDatabaseCount('personal_access_tokens', 1);
    }

    public function test_duplicate_email_and_empty_name_are_rejected(): void
    {
        $this->loginUser();
        $other = User::factory()->create();
        $this->patchJson('/api/v1/auth/profile', ['name' => '', 'email' => strtoupper($other->email)])
            ->assertUnprocessable()->assertJsonValidationErrors(['email', 'name']);
    }

    public function test_password_change_requires_current_password_and_revokes_all_sessions(): void
    {
        $user = $this->loginUser();
        $user->createToken('other');
        $data = ['current_password' => 'wrong', 'password' => 'new-password', 'password_confirmation' => 'new-password'];
        $this->postJson('/api/v1/auth/change-password', $data)->assertUnprocessable()
            ->assertJsonValidationErrors(['current_password']);
        $data['current_password'] = 'old-password';
        $this->postJson('/api/v1/auth/change-password', $data)->assertOk();
        $this->assertTrue(Hash::check('new-password', $user->fresh()->password));
        $this->assertDatabaseCount('personal_access_tokens', 0);
        $this->app['auth']->forgetGuards();
        $this->getJson('/api/v1/auth/me')->assertUnauthorized();
    }

    public function test_new_password_requires_confirmation_and_respects_byte_limit(): void
    {
        $this->loginUser();
        $this->postJson('/api/v1/auth/change-password', [
            'current_password' => 'old-password', 'password' => str_repeat('é', 37),
            'password_confirmation' => 'different',
        ])->assertUnprocessable()->assertJsonValidationErrors(['password']);
        $this->postJson('/api/v1/auth/change-password', [
            'current_password' => 'old-password', 'password' => ['not a string'],
            'password_confirmation' => ['not a string'],
        ])->assertUnprocessable()->assertJsonValidationErrors(['password']);
    }

    public function test_forgot_password_has_generic_response_for_known_and_unknown_emails(): void
    {
        Notification::fake();
        $user = User::factory()->create();
        $known = $this->postJson('/api/v1/auth/forgot-password', ['email' => strtoupper($user->email)])->assertOk();
        $unknown = $this->postJson('/api/v1/auth/forgot-password', ['email' => 'unknown@example.test'])->assertOk();
        $this->assertSame($known->json(), $unknown->json());
        Notification::assertSentTo($user, ResetPasswordToken::class);
        $this->assertDatabaseCount('password_reset_tokens', 1);
    }

    public function test_reset_token_is_single_use_and_revokes_all_sessions(): void
    {
        $user = User::factory()->create();
        $user->createToken('old session');
        $token = Password::createToken($user);
        $data = ['email' => $user->email, 'token' => $token, 'password' => 'new-password', 'password_confirmation' => 'new-password'];
        $this->postJson('/api/v1/auth/reset-password', $data)->assertOk();
        $this->assertTrue(Hash::check('new-password', $user->fresh()->password));
        $this->assertDatabaseCount('personal_access_tokens', 0);
        $this->assertDatabaseCount('password_reset_tokens', 0);
        $this->postJson('/api/v1/auth/reset-password', $data)->assertUnprocessable()->assertJsonValidationErrors(['token']);
    }

    public function test_invalid_and_expired_reset_tokens_do_not_change_password(): void
    {
        $user = User::factory()->create(['password' => 'old-password']);
        $token = Password::createToken($user);
        DB::table('password_reset_tokens')->where('email', $user->email)->update(['created_at' => now()->subMinutes(61)]);
        $this->postJson('/api/v1/auth/reset-password', [
            'email' => $user->email, 'token' => $token,
            'password' => 'new-password', 'password_confirmation' => 'new-password',
        ])->assertUnprocessable();
        $this->assertTrue(Hash::check('old-password', $user->fresh()->password));
    }

    public function test_verification_email_contains_a_working_relative_signature_and_is_throttled(): void
    {
        Notification::fake();
        $user = $this->loginUser();
        $user->forceFill(['email_verified_at' => null])->save();
        $this->postJson('/api/v1/auth/email/verification-notification')->assertOk();
        $url = null;
        Notification::assertSentTo($user, VerifyEmail::class, function ($notification) use ($user, &$url) {
            $url = $notification->toMail($user)->actionUrl;

            return true;
        });
        $this->postJson('/api/v1/auth/email/verification-notification')->assertStatus(429);
        $this->get($url)->assertOk();
        $this->assertNotNull($user->fresh()->email_verified_at);
    }

    public function test_expired_tampered_and_old_email_verification_links_are_rejected(): void
    {
        $user = User::factory()->unverified()->create();
        $path = URL::temporarySignedRoute('api.v1.auth.verify', now()->addMinutes(60), [
            'id' => $user->id, 'hash' => sha1($user->email),
        ], absolute: false);
        $this->get($path.'&extra=1')->assertForbidden();
        $user->forceFill(['email' => 'changed@example.test'])->save();
        $this->get($path)->assertForbidden();
        $this->travel(61)->minutes();
        $this->get($path)->assertForbidden();
        $this->assertNull($user->fresh()->email_verified_at);
    }

    public function test_profile_and_password_endpoints_require_authentication(): void
    {
        $this->patchJson('/api/v1/auth/profile', [])->assertUnauthorized();
        $this->postJson('/api/v1/auth/change-password', [])->assertUnauthorized();
        $this->postJson('/api/v1/auth/email/verification-notification')->assertUnauthorized();
    }
}
