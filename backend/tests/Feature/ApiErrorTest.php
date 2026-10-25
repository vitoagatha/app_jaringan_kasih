<?php

namespace Tests\Feature;

use Illuminate\Auth\AuthenticationException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use RuntimeException;
use Tests\TestCase;

class ApiErrorTest extends TestCase
{
    public function test_unknown_api_routes_return_json_even_without_an_accept_header(): void
    {
        $this->get('/api/v1/does-not-exist')->assertNotFound()->assertExactJson([
            'success' => false,
            'message' => 'Endpoint atau data tidak ditemukan.',
            'errors' => [],
        ]);
    }

    public function test_wrong_http_methods_preserve_the_allow_header(): void
    {
        $this->postJson('/api/v1/health')->assertStatus(405)
            ->assertHeader('Allow', 'GET, HEAD')
            ->assertJsonPath('success', false)
            ->assertJsonPath('message', 'Metode HTTP tidak didukung.');
    }

    public function test_validation_errors_keep_field_messages(): void
    {
        // Route ini hanya ada di aplikasi test, bukan endpoint produksi.
        Route::post('/api/v1/_test/validation', function (Request $request) {
            return $request->validate(['email' => ['required', 'email']]);
        });

        $this->postJson('/api/v1/_test/validation', ['email' => 'invalid'])
            ->assertUnprocessable()
            ->assertJsonPath('success', false)
            ->assertJsonPath('message', 'Data yang dikirim belum valid.')
            ->assertJsonValidationErrors('email');
    }

    public function test_unauthenticated_api_errors_do_not_redirect_to_a_login_page(): void
    {
        Route::get('/api/v1/_test/auth', function () {
            throw new AuthenticationException;
        });

        $this->get('/api/v1/_test/auth')->assertUnauthorized()
            ->assertJsonPath('message', 'Silakan masuk kembali.');
    }

    public function test_protected_routes_return_401_without_requesting_json(): void
    {
        $this->get('/api/v1/auth/me', ['Accept' => 'text/html'])
            ->assertUnauthorized()->assertHeader('Content-Type', 'application/json')
            ->assertJsonPath('message', 'Silakan masuk kembali.');
        $this->app['auth']->forgetGuards();
        $this->post('/api/v1/auth/logout')
            ->assertUnauthorized()->assertHeader('Content-Type', 'application/json');
    }

    public function test_unexpected_errors_hide_internal_details_even_when_debug_is_enabled(): void
    {
        config(['app.debug' => true]);
        Route::get('/api/v1/_test/error', function () {
            throw new RuntimeException('Internal credential must not be exposed');
        });

        $this->getJson('/api/v1/_test/error')->assertStatus(500)->assertExactJson([
            'success' => false,
            'message' => 'Terjadi kesalahan pada server.',
            'errors' => [],
        ])->assertDontSee('Internal credential');
    }
}
