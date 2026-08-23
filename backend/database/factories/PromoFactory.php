<?php

namespace Database\Factories;

use App\Models\Studio;
use Illuminate\Database\Eloquent\Factories\Factory;

class PromoFactory extends Factory
{
    public function definition(): array
    {
        $type = fake()->randomElement(['percentage', 'fixed']);
        
        return [
            'studio_id' => Studio::factory(),
            'code' => strtoupper(fake()->bothify('???####')),
            'name' => fake()->words(3, true) . ' Discount',
            'description' => fake()->sentence(),
            'type' => $type,
            'value' => $type === 'percentage' ? fake()->randomElement([5, 10, 15, 20, 25]) : fake()->randomElement([10000, 20000, 30000, 50000]),
            'min_booking_amount' => fake()->randomElement([0, 50000, 100000, 200000]),
            'max_discount' => $type === 'percentage' ? fake()->randomElement([20000, 50000, 100000]) : null,
            'usage_limit' => fake()->optional(0.7)->numberBetween(10, 100),
            'usage_count' => 0,
            'per_user_limit' => fake()->randomElement([1, 2, 3]),
            'start_date' => now(),
            'end_date' => now()->addMonth(),
            'is_active' => true,
        ];
    }
}
