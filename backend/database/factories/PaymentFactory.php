<?php

namespace Database\Factories;

use App\Models\Booking;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class PaymentFactory extends Factory
{
    public function definition(): array
    {
        return [
            'booking_id' => Booking::factory(),
            'user_id' => User::factory()->customer(),
            'payment_code' => 'PAY' . strtoupper(Str::random(8)),
            'provider' => fake()->randomElement(['midtrans', 'xendit']),
            'provider_payment_id' => fake()->optional()->bothify('???####'),
            'payment_url' => fake()->optional()->url(),
            'amount' => fake()->randomElement([100000, 150000, 200000, 250000, 300000]),
            'status' => fake()->randomElement(['pending', 'paid', 'failed', 'expired']),
            'payment_method' => fake()->optional()->randomElement(['bank_transfer', 'ewallet', 'va', 'credit_card']),
            'payment_type' => fake()->optional()->randomElement(['bca', 'bri', 'mandiri', 'gopay', 'ovo', 'dana']),
            'paid_at' => fake()->optional()->dateTimeBetween('-30 days', 'now'),
            'expired_at' => fake()->optional()->dateTimeBetween('now', '+7 days'),
            'raw_response' => fake()->optional()->passthrough(['status' => 'success']),
        ];
    }

    public function pending(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'pending',
            'paid_at' => null,
        ]);
    }

    public function paid(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'paid',
            'paid_at' => now(),
        ]);
    }

    public function failed(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'failed',
        ]);
    }

    public function expired(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'expired',
        ]);
    }
}
