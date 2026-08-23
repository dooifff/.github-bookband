<?php

namespace Tests\Feature\Studio;

use Tests\TestCase;
use App\Models\User;
use App\Models\Studio;
use App\Models\StudioRoom;
use App\Models\OpeningHour;
use Illuminate\Foundation\Testing\RefreshDatabase;

class StudioTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_list_studios()
    {
        Studio::factory()->count(5)->create();

        $response = $this->getJson('/api/v1/studios');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ])
            ->assertJsonStructure([
                'data' => [
                    'data' => [
                        '*' => ['id', 'name', 'slug', 'city', 'province'],
                    ],
                ],
            ]);
    }

    public function test_user_can_search_studios()
    {
        Studio::factory()->create(['name' => 'Studio Musik Jaya']);
        Studio::factory()->create(['name' => 'Studio Recording Bandung']);

        $response = $this->getJson('/api/v1/studios?search=musik');

        $response->assertStatus(200)
            ->assertJsonCount(1, 'data.data');
    }

    public function test_user_can_filter_studios_by_city()
    {
        Studio::factory()->create(['city' => 'Jakarta']);
        Studio::factory()->create(['city' => 'Bandung']);

        $response = $this->getJson('/api/v1/studios?city=Jakarta');

        $response->assertStatus(200)
            ->assertJsonCount(1, 'data.data');
    }

    public function test_user_can_get_studio_by_slug()
    {
        $studio = Studio::factory()->create();

        $response = $this->getJson("/api/v1/studios/{$studio->slug}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'id' => $studio->id,
                    'name' => $studio->name,
                ],
            ]);
    }

    public function test_user_gets_404_for_nonexistent_studio()
    {
        $response = $this->getJson('/api/v1/studios/nonexistent-studio');

        $response->assertStatus(404);
    }

    public function test_user_can_get_studio_rooms()
    {
        $studio = Studio::factory()->create();
        StudioRoom::factory()->count(3)->create(['studio_id' => $studio->id]);

        $response = $this->getJson("/api/v1/studios/{$studio->slug}/rooms");

        $response->assertStatus(200)
            ->assertJsonCount(3, 'data');
    }

    public function test_owner_can_create_studio()
    {
        $owner = User::factory()->create(['role' => 'owner']);
        $loginResponse = $this->postJson('/api/v1/auth/login', [
            'email' => $owner->email,
            'password' => 'password',
        ]);
        $token = $loginResponse->json('data.token');

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/v1/owner/studios', [
                'name' => 'New Studio',
                'address' => 'Jl. Test No. 123',
                'city' => 'Jakarta',
                'province' => 'DKI Jakarta',
                'phone' => '08123456789',
                'email' => 'studio@example.com',
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'Studio berhasil dibuat',
            ]);

        $this->assertDatabaseHas('studios', [
            'name' => 'New Studio',
            'owner_id' => $owner->id,
        ]);
    }

    public function test_customer_cannot_create_studio()
    {
        $customer = User::factory()->create(['role' => 'customer']);
        $loginResponse = $this->postJson('/api/v1/auth/login', [
            'email' => $customer->email,
            'password' => 'password',
        ]);
        $token = $loginResponse->json('data.token');

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/v1/owner/studios', [
                'name' => 'New Studio',
                'address' => 'Jl. Test No. 123',
                'city' => 'Jakarta',
                'province' => 'DKI Jakarta',
            ]);

        $response->assertStatus(403);
    }

    public function test_owner_can_update_studio()
    {
        $owner = User::factory()->create(['role' => 'owner']);
        $studio = Studio::factory()->create(['owner_id' => $owner->id]);

        $loginResponse = $this->postJson('/api/v1/auth/login', [
            'email' => $owner->email,
            'password' => 'password',
        ]);
        $token = $loginResponse->json('data.token');

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->putJson("/api/v1/owner/studios/{$studio->id}", [
                'name' => 'Updated Studio Name',
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Studio berhasil diupdate',
            ]);

        $this->assertDatabaseHas('studios', [
            'id' => $studio->id,
            'name' => 'Updated Studio Name',
        ]);
    }

    public function test_owner_can_delete_studio()
    {
        $owner = User::factory()->create(['role' => 'owner']);
        $studio = Studio::factory()->create(['owner_id' => $owner->id]);

        $loginResponse = $this->postJson('/api/v1/auth/login', [
            'email' => $owner->email,
            'password' => 'password',
        ]);
        $token = $loginResponse->json('data.token');

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->deleteJson("/api/v1/owner/studios/{$studio->id}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Studio berhasil dihapus',
            ]);

        $this->assertSoftDeleted('studios', ['id' => $studio->id]);
    }

    public function test_owner_cannot_delete_other_owners_studio()
    {
        $owner1 = User::factory()->create(['role' => 'owner']);
        $owner2 = User::factory()->create(['role' => 'owner']);
        $studio = Studio::factory()->create(['owner_id' => $owner2->id]);

        $loginResponse = $this->postJson('/api/v1/auth/login', [
            'email' => $owner1->email,
            'password' => 'password',
        ]);
        $token = $loginResponse->json('data.token');

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->deleteJson("/api/v1/owner/studios/{$studio->id}");

        $response->assertStatus(403);
    }
}
