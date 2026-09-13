<?php

namespace Tests\Feature\Booking;

use Tests\TestCase;
use App\Models\User;
use App\Models\Studio;
use App\Models\StudioRoom;
use App\Models\Booking;
use App\Models\OpeningHour;
use Illuminate\Foundation\Testing\RefreshDatabase;

class BookingTest extends TestCase
{
    use RefreshDatabase;

    protected $user;
    protected $token;
    protected $studio;
    protected $room;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create(['role' => 'customer']);
        $this->studio = Studio::factory()->create([
            'is_active' => true,
            'is_verified' => true,
        ]);
        $this->room = StudioRoom::factory()->create([
            'studio_id' => $this->studio->id,
            'price_per_hour' => 50000,
        ]);

        // Future Monday (dayOfWeekIso = 1) so booking dates are valid
        $this->date = now()->next(\Carbon\Carbon::MONDAY)->format('Y-m-d');

        OpeningHour::factory()->create([
            'studio_id' => $this->studio->id,
            'day_of_week' => 1, // Monday
            'open_time' => '09:00',
            'close_time' => '21:00',
            'is_closed' => false,
        ]);

        $loginResponse = $this->postJson('/api/v1/auth/login', [
            'email' => $this->user->email,
            'password' => 'password',
        ]);

        $this->token = $loginResponse->json('data.token');
    }

    public function test_user_can_create_booking()
    {
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson('/api/v1/bookings', [
                'studio_id' => $this->studio->id,
                'room_id' => $this->room->id,
                'date' => $this->date,
                'start_time' => '10:00',
                'end_time' => '12:00',
                'notes' => 'Test booking',
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'Booking berhasil dibuat',
            ])
            ->assertJsonStructure([
                'data' => [
                    'id',
                    'booking_code',
                    'status',
                    'pricing',
                ],
            ]);

        $this->assertDatabaseHas('bookings', [
            'user_id' => $this->user->id,
            'studio_id' => $this->studio->id,
            'status' => 'pending',
        ]);
    }

    public function test_user_cannot_create_booking_without_auth()
    {
        $response = $this->postJson('/api/v1/bookings', [
            'studio_id' => $this->studio->id,
            'room_id' => $this->room->id,
            'booking_date' => '2025-03-17',
            'start_time' => '10:00',
            'end_time' => '12:00',
        ]);

        $response->assertStatus(401);
    }

    public function test_user_can_list_bookings()
    {
        Booking::factory()->count(3)->create(['user_id' => $this->user->id]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->getJson('/api/v1/bookings');

        $response->assertStatus(200)
            ->assertJsonCount(3, 'data');
    }

    public function test_user_can_get_booking_detail()
    {
        $booking = Booking::factory()->create([
            'user_id' => $this->user->id,
            'studio_id' => $this->studio->id,
            'room_id' => $this->room->id,
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->getJson("/api/v1/bookings/{$booking->id}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'id' => $booking->id,
                    'booking_code' => $booking->booking_code,
                ],
            ]);
    }

    public function test_user_can_get_booking_by_code()
    {
        $booking = Booking::factory()->create([
            'user_id' => $this->user->id,
            'studio_id' => $this->studio->id,
            'room_id' => $this->room->id,
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->getJson("/api/v1/bookings/code/{$booking->booking_code}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'id' => $booking->id,
                ],
            ]);
    }

    public function test_user_can_cancel_booking()
    {
        $booking = Booking::factory()->create([
            'user_id' => $this->user->id,
            'status' => 'pending',
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson("/api/v1/bookings/{$booking->id}/cancel");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Booking berhasil dibatalkan',
            ]);

        $this->assertDatabaseHas('bookings', [
            'id' => $booking->id,
            'status' => 'cancelled',
        ]);
    }

    public function test_user_cannot_cancel_completed_booking()
    {
        $booking = Booking::factory()->create([
            'user_id' => $this->user->id,
            'status' => 'completed',
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson("/api/v1/bookings/{$booking->id}/cancel");

        $response->assertStatus(422)
            ->assertJson([
                'success' => false,
            ]);
    }

    public function test_user_cannot_cancel_other_users_booking()
    {
        $otherUser = User::factory()->create(['role' => 'customer']);
        $booking = Booking::factory()->create([
            'user_id' => $otherUser->id,
            'status' => 'confirmed',
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson("/api/v1/bookings/{$booking->id}/cancel");

        $response->assertStatus(422);
    }

    public function test_user_cannot_create_overlapping_booking()
    {
        // Create existing booking
        Booking::factory()->create([
            'studio_id' => $this->studio->id,
            'room_id' => $this->room->id,
            'date' => $this->date,
            'start_time' => '10:00',
            'end_time' => '12:00',
            'status' => 'confirmed',
        ]);

        // Try to create overlapping booking
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson('/api/v1/bookings', [
                'studio_id' => $this->studio->id,
                'room_id' => $this->room->id,
                'date' => $this->date,
                'start_time' => '11:00',
                'end_time' => '13:00',
            ]);

        $response->assertStatus(422)
            ->assertJson([
                'success' => false,
            ]);
    }
}
