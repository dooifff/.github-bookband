<?php

namespace Database\Factories;

use App\Models\Studio;
use App\Models\StudioRoom;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class BookingFactory extends Factory
{
    public function definition(): array
    {
        $startHour = fake()->numberBetween(8, 20);
        $duration = fake()->numberBetween(1, 4);
        
        return [
            'user_id' => User::factory()->customer(),
            'studio_id' => Studio::factory(),
            'room_id' => StudioRoom::factory(),
            'booking_code' => 'SB' . strtoupper(Str::random(8)),
            'date' => fake()->dateTimeBetween('+1 day', '+30 day')->format('Y-m-d'),
            'start_time' => sprintf('%02d:00:00', $startHour),
            'end_time' => sprintf('%02d:00:00', $startHour + $duration),
            'duration_hours' => $duration,
            'price_per_hour' => fake()->randomElement([100000, 150000, 200000, 250000]),
            'subtotal' => 0,
            'discount' => 0,
            'total' => 0,
            'status' => fake()->randomElement(['pending', 'awaiting_payment', 'paid', 'confirmed']),
            'notes' => fake()->optional()->sentence(),
        ];
    }

    public function pending(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'pending',
        ]);
    }

    public function paid(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'paid',
            'paid_at' => now(),
        ]);
    }

    public function confirmed(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'confirmed',
            'paid_at' => now(),
            'confirmed_at' => now(),
        ]);
    }

    public function completed(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'completed',
            'paid_at' => now(),
            'confirmed_at' => now(),
            'completed_at' => now(),
        ]);
    }

    public function cancelled(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'cancelled',
            'cancel_reason' => fake()->sentence(),
            'cancelled_at' => now(),
        ]);
    }
}
