<?php

namespace Tests\Feature\Auth;

use App\Models\User;
use App\Services\GoogleAuthService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;
use Tests\TestCase;

class GoogleLoginTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Ganti GoogleAuthService dengan versi palsu supaya test tidak memanggil Google.
     */
    private function fakeGoogleAuth(array $claims, ?string $invalidToken = null): void
    {
        $fake = new class extends GoogleAuthService
        {
            /** @var array<string, mixed> */
            public array $claims = [];

            public ?string $invalidToken = null;

            public function verifyIdToken(string $idToken): array
            {
                if ($this->invalidToken !== null && $idToken === $this->invalidToken) {
                    throw ValidationException::withMessages([
                        'id_token' => ['Token Google tidak valid atau sudah kedaluwarsa.'],
                    ]);
                }

                return $this->claims;
            }
        };

        $fake->claims = $claims;
        $fake->invalidToken = $invalidToken;

        $this->app->instance(GoogleAuthService::class, $fake);
    }

    private function claims(array $overrides = []): array
    {
        return array_merge([
            'iss' => 'https://accounts.google.com',
            'aud' => 'test-client-id.apps.googleusercontent.com',
            'sub' => '1234567890',
            'email' => 'googleuser@gmail.com',
            'email_verified' => true,
            'name' => 'Google User',
            'picture' => 'https://example.com/avatar.jpg',
        ], $overrides);
    }

    public function test_new_google_user_is_registered_and_receives_token()
    {
        $this->fakeGoogleAuth($this->claims());

        $response = $this->postJson('/api/v1/auth/google', ['id_token' => 'fake-token']);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'Registrasi berhasil',
                'data' => ['is_new_user' => true],
            ])
            ->assertJsonStructure([
                'data' => [
                    'user' => ['id', 'name', 'email', 'role'],
                    'token',
                ],
            ]);

        $this->assertDatabaseHas('users', [
            'email' => 'googleuser@gmail.com',
            'google_id' => '1234567890',
            'role' => 'customer',
            'avatar' => 'https://example.com/avatar.jpg',
        ]);

        // User Google tidak punya password lokal.
        $this->assertNull(User::where('email', 'googleuser@gmail.com')->first()->password);
    }

    public function test_new_google_user_can_register_as_owner()
    {
        $this->fakeGoogleAuth($this->claims());

        $this->postJson('/api/v1/auth/google', [
            'id_token' => 'fake-token',
            'role' => 'owner',
        ])->assertStatus(201);

        $this->assertDatabaseHas('users', [
            'email' => 'googleuser@gmail.com',
            'role' => 'owner',
        ]);
    }

    public function test_existing_email_is_linked_and_logged_in()
    {
        $user = User::factory()->create([
            'email' => 'googleuser@gmail.com',
            'password' => Hash::make('password123'),
        ]);

        $this->fakeGoogleAuth($this->claims());

        $this->postJson('/api/v1/auth/google', ['id_token' => 'fake-token'])
            ->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Login berhasil',
                'data' => ['is_new_user' => false],
            ]);

        $this->assertSame($user->id, User::where('email', 'googleuser@gmail.com')->first()->id);
        $this->assertSame('1234567890', $user->fresh()->google_id);
    }

    public function test_returning_google_user_is_logged_in_without_duplicate_account()
    {
        $user = User::factory()->create([
            'email' => 'googleuser@gmail.com',
            'google_id' => '1234567890',
        ]);

        $this->fakeGoogleAuth($this->claims());

        $this->postJson('/api/v1/auth/google', ['id_token' => 'fake-token'])
            ->assertStatus(200);

        $this->assertSame(1, User::where('email', 'googleuser@gmail.com')->count());
        $this->assertSame($user->id, User::where('google_id', '1234567890')->first()->id);
    }

    public function test_unverified_google_email_is_rejected()
    {
        $this->fakeGoogleAuth($this->claims(['email_verified' => false]));

        $this->postJson('/api/v1/auth/google', ['id_token' => 'fake-token'])
            ->assertStatus(422);

        $this->assertDatabaseCount('users', 0);
    }

    public function test_invalid_google_token_is_rejected()
    {
        $this->fakeGoogleAuth($this->claims(), invalidToken: 'invalid');

        $this->postJson('/api/v1/auth/google', ['id_token' => 'invalid'])
            ->assertStatus(422)
            ->assertJson(['errors' => ['id_token' => ['Token Google tidak valid atau sudah kedaluwarsa.']]]);

        $this->assertDatabaseCount('users', 0);
    }

    public function test_id_token_is_required()
    {
        $this->postJson('/api/v1/auth/google', [])
            ->assertStatus(422)
            ->assertJsonValidationErrors('id_token');
    }

    public function test_google_only_user_cannot_login_with_password()
    {
        User::factory()->create([
            'email' => 'googleuser@gmail.com',
            'google_id' => '1234567890',
            'password' => null,
        ]);

        $this->postJson('/api/v1/auth/login', [
            'email' => 'googleuser@gmail.com',
            'password' => 'password123',
        ])->assertStatus(422);
    }
}
