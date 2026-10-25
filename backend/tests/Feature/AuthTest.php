<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Tests\PostgresTestCase;

class AuthTest extends PostgresTestCase
{
    private function registration(array $overrides = []): array
    {
        return array_replace([
            'name' => 'Vito',
            'email' => 'vito@example.test',
            'password' => 'belajar-password',
            'password_confirmation' => 'belajar-password',
            'device_name' => 'Flutter test',
        ], $overrides);
    }

    public function test_registration_normalizes_email_hashes_password_and_issues_a_hashed_token(): void
    {
        $response = $this->postJson('/api/v1/auth/register', $this->registration(['email' => ' VITO@Example.Test ']))
            ->assertCreated()->assertJsonPath('success', true)
            ->assertJsonPath('data.user.email', 'vito@example.test')
            ->assertJsonPath('data.user.email_verified_at', null)
            ->assertJsonPath('data.token_type', 'Bearer');
        $this->assertStringContainsString('no-store', $response->headers->get('Cache-Control'));
        $this->assertArrayNotHasKey('password', $response->json('data.user'));
        $user = User::firstOrFail();
        $this->assertTrue(Hash::check('belajar-password', $user->password));
        $this->assertDatabaseCount('personal_access_tokens', 1);
        [, $secret] = explode('|', $response->json('data.token'), 2);
        $this->assertSame(hash('sha256', $secret), $user->tokens()->first()->token);
        $this->assertSame(now()->addDays(7)->timestamp, strtotime($response->json('data.expires_at')));
    }

    public function test_registration_validates_fields_and_password_confirmation(): void
    {
        $this->postJson('/api/v1/auth/register', $this->registration([
            'name' => '', 'email' => 'invalid', 'password' => 'short',
            'password_confirmation' => 'different', 'device_name' => '',
        ]))->assertUnprocessable()->assertJsonValidationErrors(['name', 'email', 'password', 'device_name'], 'errors');
        $this->assertDatabaseCount('users', 0);
        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    public function test_duplicate_email_is_rejected_case_insensitively(): void
    {
        User::factory()->create(['email' => 'vito@example.test']);
        $this->postJson('/api/v1/auth/register', $this->registration(['email' => 'VITO@example.test']))
            ->assertUnprocessable()->assertJsonValidationErrors(['email'], 'errors');
        $this->assertDatabaseCount('users', 1);
    }

    public function test_password_is_not_trimmed_and_bcrypt_byte_limit_is_validated(): void
    {
        $this->postJson('/api/v1/auth/register', $this->registration([
            'password' => str_repeat('é', 37), 'password_confirmation' => str_repeat('é', 37),
        ]))->assertUnprocessable()->assertJsonValidationErrors(['password'], 'errors');
        $password = '  belajar-password  ';
        $this->postJson('/api/v1/auth/register', $this->registration([
            'password' => $password, 'password_confirmation' => $password,
        ]))->assertCreated();
        $this->assertTrue(Hash::check($password, User::firstOrFail()->password));
    }

    public function test_login_accepts_normalized_email_and_returns_only_public_user_fields(): void
    {
        $user = User::factory()->create(['email' => 'vito@example.test', 'password' => 'belajar-password']);
        $this->postJson('/api/v1/auth/login', $this->registration(['email' => ' VITO@example.test ']))
            ->assertOk()->assertJsonPath('data.user.id', $user->id)
            ->assertJsonStructure(['data' => ['token', 'expires_at']])
            ->assertJsonMissingPath('data.user.password')->assertJsonMissingPath('data.user.remember_token');
    }

    public function test_wrong_password_and_unknown_email_have_the_same_error(): void
    {
        User::factory()->create(['email' => 'vito@example.test']);
        $wrong = $this->postJson('/api/v1/auth/login', $this->registration())->assertUnauthorized();
        $unknown = $this->postJson('/api/v1/auth/login', $this->registration(['email' => 'unknown@example.test']))
            ->assertUnauthorized();
        $this->assertSame($wrong->json(), $unknown->json());
        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    public function test_login_requires_valid_fields(): void
    {
        $this->postJson('/api/v1/auth/login', ['email' => ['invalid'], 'password' => [], 'device_name' => []])
            ->assertUnprocessable()->assertJsonValidationErrors(['email', 'password', 'device_name'], 'errors');
    }

    public function test_me_requires_a_real_bearer_token_and_returns_its_owner(): void
    {
        $this->getJson('/api/v1/auth/me')->assertUnauthorized();
        $this->app['auth']->forgetGuards();
        $this->withToken('invalid')->getJson('/api/v1/auth/me')->assertUnauthorized();
        $this->app['auth']->forgetGuards();
        $user = User::factory()->create();
        $token = $user->createToken('test')->plainTextToken;
        $this->withToken($token)->getJson('/api/v1/auth/me')->assertOk()
            ->assertJsonPath('data.user.id', $user->id)->assertJsonMissingPath('data.user.password');
    }

    public function test_expired_tokens_are_rejected(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('test', ['*'], now()->addDays(7))->plainTextToken;
        $this->travel(8)->days();
        $this->withToken($token)->getJson('/api/v1/auth/me')->assertUnauthorized();
    }

    public function test_logout_revokes_only_the_current_token_and_it_cannot_be_reused(): void
    {
        $user = User::factory()->create();
        $current = $user->createToken('current')->plainTextToken;
        $other = $user->createToken('other')->plainTextToken;
        $this->withToken($current)->postJson('/api/v1/auth/logout')->assertOk()->assertJsonPath('data', null);
        $this->assertSame(['other'], $user->tokens()->pluck('name')->all());
        $this->app['auth']->forgetGuards();
        $this->withToken($current)->getJson('/api/v1/auth/me')->assertUnauthorized();
        $this->app['auth']->forgetGuards();
        $this->withToken($other)->getJson('/api/v1/auth/me')->assertOk();
    }

    public function test_revoked_tokens_return_401_without_an_accept_header(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('revoked');
        $plainText = $token->plainTextToken;
        $token->accessToken->delete();

        $this->withToken($plainText)->post('/api/v1/auth/logout')
            ->assertUnauthorized()->assertJsonPath('message', 'Silakan masuk kembali.');
        $this->app['auth']->forgetGuards();
        $this->withToken($plainText)->get('/api/v1/auth/me')
            ->assertUnauthorized()->assertHeader('Content-Type', 'application/json');
    }

    public function test_logout_without_a_token_is_rejected(): void
    {
        $this->postJson('/api/v1/auth/logout')->assertUnauthorized();
    }

    public function test_login_is_rate_limited_even_with_alternating_email_case(): void
    {
        for ($i = 0; $i < 5; $i++) {
            $this->postJson('/api/v1/auth/login', $this->registration([
                'email' => $i % 2 === 0 ? 'VITO@example.test' : 'vito@example.test',
            ]))->assertUnauthorized();
        }
        $this->postJson('/api/v1/auth/login', $this->registration())
            ->assertStatus(429)->assertHeader('Retry-After')->assertJsonPath('success', false);
    }

    public function test_registration_is_rate_limited(): void
    {
        for ($i = 0; $i < 5; $i++) {
            $this->postJson('/api/v1/auth/register', [])->assertUnprocessable();
        }
        $this->postJson('/api/v1/auth/register', [])->assertStatus(429)->assertHeader('Retry-After');
    }
}
