<?php

namespace Tests\Feature\Favorite;

use Tests\TestCase;
use App\Models\User;
use App\Models\Studio;
use App\Models\Favorite;
use Illuminate\Foundation\Testing\RefreshDatabase;

class FavoriteTest extends TestCase
{
    use RefreshDatabase;

    protected $user;
    protected $token;
    protected $studio;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create(['role' => 'customer']);
        $this->studio = Studio::factory()->create();

        $loginResponse = $this->postJson('/api/v1/auth/login', [
            'email' => $this->user->email,
            'password' => 'password',
        ]);

        $this->token = $loginResponse->json('data.token');
    }

    public function test_user_can_toggle_favorite()
    {
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson('/api/v1/favorites/toggle', [
                'studio_id' => $this->studio->id,
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);

        $this->assertDatabaseHas('favorites', [
            'user_id' => $this->user->id,
            'studio_id' => $this->studio->id,
        ]);
    }

    public function test_user_can_remove_favorite()
    {
        Favorite::factory()->create([
            'user_id' => $this->user->id,
            'studio_id' => $this->studio->id,
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->deleteJson("/api/v1/favorites/{$this->studio->id}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);

        $this->assertDatabaseMissing('favorites', [
            'user_id' => $this->user->id,
            'studio_id' => $this->studio->id,
        ]);
    }

    public function test_user_can_list_favorites()
    {
        Favorite::factory()->count(3)->create([
            'user_id' => $this->user->id,
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->getJson('/api/v1/favorites');

        $response->assertStatus(200)
            ->assertJsonCount(3, 'data');
    }

    public function test_user_can_check_favorite_status()
    {
        Favorite::factory()->create([
            'user_id' => $this->user->id,
            'studio_id' => $this->studio->id,
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->getJson("/api/v1/favorites/check/{$this->studio->id}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'is_favorited' => true,
                ],
            ]);
    }

    public function test_unauthenticated_user_cannot_toggle_favorite()
    {
        $response = $this->postJson('/api/v1/favorites/toggle', [
            'studio_id' => $this->studio->id,
        ]);

        $response->assertStatus(401);
    }
}
