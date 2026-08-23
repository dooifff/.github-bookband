<?php

namespace Database\Factories;

use App\Models\Studio;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class FavoriteFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::factory()->customer(),
            'studio_id' => Studio::factory(),
        ];
    }
}
