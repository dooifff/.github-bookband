<?php

namespace Database\Seeders;

use App\Models\Booking;
use App\Models\Favorite;
use App\Models\OpeningHour;
use App\Models\Payment;
use App\Models\Review;
use App\Models\Studio;
use App\Models\StudioRoom;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

/**
 * Lightweight seeder for quick testing
 * Run: php artisan db:seed --class=TestSeeder
 */
class TestSeeder extends Seeder
{
    public function run(): void
    {
        $this->command->info('🧪 Creating test data...');

        // Create test accounts
        $admin = User::factory()->superAdmin()->create([
            'name' => 'Admin',
            'email' => 'admin@test.com',
            'password' => Hash::make('password'),
        ]);

        $owner = User::factory()->owner()->create([
            'name' => 'Owner',
            'email' => 'owner@test.com',
            'password' => Hash::make('password'),
        ]);

        $customer = User::factory()->customer()->create([
            'name' => 'Customer',
            'email' => 'customer@test.com',
            'password' => Hash::make('password'),
        ]);

        // Create studio
        $studio = Studio::factory()->create([
            'owner_id' => $owner->id,
            'name' => 'Test Studio',
            'city' => 'Jakarta',
            'is_verified' => true,
        ]);

        // Create rooms
        $room = StudioRoom::factory()->create([
            'studio_id' => $studio->id,
            'name' => 'Main Room',
            'price_per_hour' => 150000,
        ]);

        // Create opening hours
        for ($day = 1; $day <= 6; $day++) {
            OpeningHour::create([
                'studio_id' => $studio->id,
                'day_of_week' => $day,
                'open_time' => '09:00',
                'close_time' => '22:00',
                'is_closed' => false,
            ]);
        }

        // Create booking
        $booking = Booking::factory()->create([
            'user_id' => $customer->id,
            'studio_id' => $studio->id,
            'room_id' => $room->id,
            'status' => 'confirmed',
            'total' => 300000,
        ]);

        // Create payment
        Payment::factory()->create([
            'booking_id' => $booking->id,
            'user_id' => $customer->id,
            'amount' => 300000,
            'status' => 'paid',
        ]);

        // Create review
        Review::factory()->create([
            'user_id' => $customer->id,
            'studio_id' => $studio->id,
            'rating' => 5,
            'comment' => 'Great studio!',
        ]);

        // Create favorite
        Favorite::create([
            'user_id' => $customer->id,
            'studio_id' => $studio->id,
        ]);

        $this->command->info('✅ Test data created!');
        $this->command->info('  Admin:    admin@test.com / password');
        $this->command->info('  Owner:    owner@test.com / password');
        $this->command->info('  Customer: customer@test.com / password');
    }
}
