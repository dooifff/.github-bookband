<?php

namespace Database\Factories;

use App\Models\Booking;
use App\Models\Studio;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class ReviewFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::factory()->customer(),
            'studio_id' => Studio::factory(),
            'booking_id' => null,
            'rating' => fake()->numberBetween(1, 5),
            'comment' => fake()->paragraph(),
            'is_anonymous' => fake()->boolean(20),
            'is_approved' => true,
        ];
    }
}
