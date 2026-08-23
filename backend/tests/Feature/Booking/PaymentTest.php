<?php

namespace Tests\Feature\Booking;

use Tests\TestCase;
use App\Models\User;
use App\Models\Studio;
use App\Models\StudioRoom;
use App\Models\Booking;
use App\Models\Payment;
use Illuminate\Foundation\Testing\RefreshDatabase;

class PaymentTest extends TestCase
{
    use RefreshDatabase;

    protected $user;
    protected $token;
    protected $booking;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create(['role' => 'customer']);
        $studio = Studio::factory()->create();
        $room = StudioRoom::factory()->create(['studio_id' => $studio->id]);

        $this->booking = Booking::factory()->create([
            'user_id' => $this->user->id,
            'studio_id' => $studio->id,
            'room_id' => $room->id,
            'status' => 'pending',
            'total_amount' => 100000,
        ]);

        $loginResponse = $this->postJson('/api/v1/auth/login', [
            'email' => $this->user->email,
            'password' => 'password',
        ]);

        $this->token = $loginResponse->json('data.token');
    }    public function test_user_can_create_payment()
    {
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson('/api/v1/payments', [
                'booking_id' => $this->booking->id,
                'payment_method' => 'bank_transfer',
                'provider' => 'midtrans',
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'Pembayaran berhasil dibuat',
            ])
            ->assertJsonStructure([
                'data' => [
                    'id', 'payment_code', 'amount', 'status', 'payment_url',
                ],
            ]);

        $this->assertDatabaseHas('payments', [
            'booking_id' => $this->booking->id,
            'status' => 'pending',
        ]);
    }

    public function test_user_cannot_create_payment_for_other_users_booking()
    {
        $otherUser = User::factory()->create(['role' => 'customer']);
        $booking = Booking::factory()->create([
            'user_id' => $otherUser->id,
            'status' => 'pending',
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson('/api/v1/payments', [
                'booking_id' => $booking->id,
                'payment_method' => 'bank_transfer',
                'bank_code' => 'bca',
            ]);

        $response->assertStatus(403);
    }

    public function test_user_can_check_payment_status()
    {
        $payment = Payment::factory()->create([
            'booking_id' => $this->booking->id,
            'status' => 'pending',
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->getJson("/api/v1/payments/{$payment->payment_code}/status");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);
    }

    public function test_user_can_get_payment_history()
    {
        Payment::factory()->count(3)->create([
            'booking_id' => $this->booking->id,
            'user_id' => $this->user->id,
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->getJson('/api/v1/payment-history');

        $response->assertStatus(200)
            ->assertJsonCount(3, 'data.data');
    }

    public function test_user_cannot_create_payment_without_auth()
    {
        $response = $this->postJson('/api/v1/payments', [
            'booking_id' => $this->booking->id,
            'payment_method' => 'bank_transfer',
            'bank_code' => 'bca',
        ]);

        $response->assertStatus(401);
    }
}
