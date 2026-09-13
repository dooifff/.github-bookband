<?php

namespace Tests\Feature\Review;

use Tests\TestCase;
use App\Models\User;
use App\Models\Studio;
use App\Models\Booking;
use App\Models\Review;
use Illuminate\Foundation\Testing\RefreshDatabase;

class ReviewTest extends TestCase
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

    public function test_user_can_create_review()
    {
        $booking = Booking::factory()->create([
            'user_id' => $this->user->id,
            'studio_id' => $this->studio->id,
            'status' => 'completed',
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson('/api/v1/reviews', [
                'studio_id' => $this->studio->id,
                'booking_id' => $booking->id,
                'rating' => 5,
                'comment' => 'Great studio!',
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'Review berhasil dikirim',
            ]);

        $this->assertDatabaseHas('reviews', [
            'user_id' => $this->user->id,
            'studio_id' => $this->studio->id,
            'rating' => 5,
        ]);
    }

    public function test_user_cannot_create_review_without_booking()
    {
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson('/api/v1/reviews', [
                'studio_id' => $this->studio->id,
                'rating' => 5,
                'comment' => 'Great studio!',
            ]);

        $response->assertStatus(422);
    }

    public function test_user_cannot_review_same_studio_twice()
    {
        $booking = Booking::factory()->create([
            'user_id' => $this->user->id,
            'studio_id' => $this->studio->id,
            'status' => 'completed',
        ]);

        Review::factory()->create([
            'user_id' => $this->user->id,
            'studio_id' => $this->studio->id,
            'booking_id' => $booking->id,
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson('/api/v1/reviews', [
                'studio_id' => $this->studio->id,
                'booking_id' => $booking->id,
                'rating' => 4,
                'comment' => 'Another review',
            ]);

        $response->assertStatus(409)
            ->assertJson([
                'success' => false,
            ]);
    }

    public function test_user_can_list_reviews()
    {
        Review::factory()->count(5)->create([
            'studio_id' => $this->studio->id,
        ]);

        $response = $this->getJson("/api/v1/studios/{$this->studio->slug}/reviews");

        $response->assertStatus(200)
            ->assertJsonCount(5, 'data');
    }

    public function test_user_can_get_my_reviews()
    {
        Review::factory()->count(3)->create([
            'user_id' => $this->user->id,
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->getJson('/api/v1/reviews/my-reviews');

        $response->assertStatus(200)
            ->assertJsonCount(3, 'data');
    }

    public function test_user_can_delete_own_review()
    {
        $review = Review::factory()->create([
            'user_id' => $this->user->id,
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->deleteJson("/api/v1/reviews/{$review->id}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Review berhasil dihapus',
            ]);

        $this->assertSoftDeleted('reviews', ['id' => $review->id]);
    }

    public function test_user_cannot_delete_other_users_review()
    {
        $otherUser = User::factory()->create(['role' => 'customer']);
        $review = Review::factory()->create([
            'user_id' => $otherUser->id,
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->deleteJson("/api/v1/reviews/{$review->id}");

        $response->assertStatus(403);
    }
}
