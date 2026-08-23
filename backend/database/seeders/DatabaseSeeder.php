<?php

namespace Database\Seeders;

use App\Models\Band;
use App\Models\BandMember;
use App\Models\Booking;
use App\Models\Favorite;
use App\Models\Notification;
use App\Models\OpeningHour;
use App\Models\Payment;
use App\Models\Promo;
use App\Models\Review;
use App\Models\Studio;
use App\Models\StudioRoom;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $this->command->info('🌱 Seeding database...');

        // ============================================
        // 1. Create Users
        // ============================================
        $this->createUsers();

        // ============================================
        // 2. Create Studios with Rooms & Equipment
        // ============================================
        $this->createStudios();

        // ============================================
        // 3. Create Bookings & Payments
        // ============================================
        $this->createBookings();

        // ============================================
        // 4. Create Reviews
        // ============================================
        $this->createReviews();

        // ============================================
        // 5. Create Favorites
        // ============================================
        $this->createFavorites();

        // ============================================
        // 6. Create Bands
        // ============================================
        $this->createBands();

        // ============================================
        // 7. Create Promos
        // ============================================
        $this->createPromos();

        // ============================================
        // 8. Create Notifications
        // ============================================
        $this->createNotifications();

        $this->command->info('');
        $this->command->info('✅ Database seeded successfully!');
        $this->command->info('');
        $this->command->info('📋 Default accounts:');
        $this->command->info('  Super Admin: admin@studiobook.com / password');
        $this->command->info('  Owner:       owner@studiobook.com / password');
        $this->command->info('  Customer:    customer@studiobook.com / password');
        $this->command->info('');
        $this->command->info('📊 Sample data created:');
        $this->command->info('  - ' . User::count() . ' users');
        $this->command->info('  - ' . Studio::count() . ' studios');
        $this->command->info('  - ' . StudioRoom::count() . ' rooms');
        $this->command->info('  - ' . Booking::count() . ' bookings');
        $this->command->info('  - ' . Review::count() . ' reviews');
        $this->command->info('  - ' . Favorite::count() . ' favorites');
        $this->command->info('  - ' . Band::count() . ' bands');
        $this->command->info('  - ' . Promo::count() . ' promos');
        $this->command->info('  - ' . Notification::count() . ' notifications');

    }

    /**
     * Create users (admin, owners, customers)
     */
    private function createUsers(): void
    {
        $this->command->info('Creating users...');

        // Super Admin
        User::factory()->superAdmin()->create([
            'name' => 'Super Admin',
            'email' => 'admin@studiobook.com',
            'password' => Hash::make('password'),
            'phone' => '081000000001',
        ]);

        // Admin
        User::factory()->admin()->create([
            'name' => 'Admin StudioBook',
            'email' => 'admin2@studiobook.com',
            'password' => Hash::make('password'),
            'phone' => '081000000002',
        ]);

        // Named Owner (for easy testing)
        User::factory()->owner()->create([
            'name' => 'Studio Owner',
            'email' => 'owner@studiobook.com',
            'password' => Hash::make('password'),
            'phone' => '081234567890',
        ]);

        // Extra Owners
        User::factory()->owner()->count(4)->create();

        // Named Customer (for easy testing)
        User::factory()->customer()->create([
            'name' => 'Test Customer',
            'email' => 'customer@studiobook.com',
            'password' => Hash::make('password'),
            'phone' => '081987654321',
        ]);

        // Extra Customers
        User::factory()->customer()->count(14)->create();
    }

    /**
     * Create studios with rooms and opening hours
     */
    private function createStudios(): void
    {
        $this->command->info('Creating studios...');

        $owners = User::where('role', 'owner')->get();

        $studioNames = [
            'Studio Melody',
            'Studio Harmony',
            'Studio Rhythm',
            'Studio Sonic',
            'Studio Vibes',
            'Studio Pulse',
            'Studio Echo',
            'Studio Wave',
            'Studio Beat',
            'Studio Sound',
        ];

        foreach ($owners as $index => $owner) {
            $name = $studioNames[$index % count($studioNames)];
            
            $studio = Studio::factory()->create([
                'owner_id' => $owner->id,
                'name' => $name . ' ' . ($owner->id),
                'city' => ['Jakarta', 'Bandung', 'Surabaya', 'Yogyakarta', 'Semarang'][$index % 5],
                'province' => ['DKI Jakarta', 'Jawa Barat', 'Jawa Timur', 'DI Yogyakarta', 'Jawa Tengah'][$index % 5],
                'is_verified' => $index < 3, // First 3 studios verified
                'is_active' => true,
            ]);

            // Create rooms (2-4 per studio)
            $roomCount = rand(2, 4);
            StudioRoom::factory()->count($roomCount)->create([
                'studio_id' => $studio->id,
            ]);

            // Create opening hours (Mon-Sat 09:00-22:00, Sunday closed)
            for ($day = 1; $day <= 7; $day++) {
                OpeningHour::create([
                    'studio_id' => $studio->id,
                    'day_of_week' => $day,
                    'open_time' => $day == 6 ? '10:00' : '09:00', // Saturday opens later
                    'close_time' => $day == 6 ? '23:00' : '22:00',
                    'is_closed' => $day == 7, // Sunday closed
                ]);
            }
        }
    }

    /**
     * Create bookings and payments
     */
    private function createBookings(): void
    {
        $this->command->info('Creating bookings...');

        $customers = User::where('role', 'customer')->get();
        $studios = Studio::all();

        foreach ($customers as $customer) {
            // Create 2-5 bookings per customer
            $bookingCount = rand(2, 5);
            
            for ($i = 0; $i < $bookingCount; $i++) {
                $studio = $studios->random();
                $room = $studio->rooms->random();
                
                // Random date in the past or future
                $date = \Carbon\Carbon::parse(fake()->dateTimeBetween('-30 days', '+30 days'));
                $startHour = rand(9, 18);
                $duration = rand(1, 4);
                
                // Determine status based on date
                if ($date->isPast()) {
                    $status = fake()->randomElement(['completed', 'cancelled']);
                } else {
                    $status = fake()->randomElement(['pending', 'awaiting_payment', 'confirmed']);
                }
                
                $pricePerHour = $room->price_per_hour;
                $subtotal = $pricePerHour * $duration;
                $discount = rand(0, 1) ? $subtotal * 0.1 : 0; // 10% discount sometimes
                $total = $subtotal - $discount;
                
                $booking = Booking::factory()->create([
                    'user_id' => $customer->id,
                    'studio_id' => $studio->id,
                    'room_id' => $room->id,
                    'date' => $date->format('Y-m-d'),
                    'start_time' => sprintf('%02d:00:00', $startHour),
                    'end_time' => sprintf('%02d:00:00', $startHour + $duration),
                    'duration_hours' => $duration,
                    'price_per_hour' => $pricePerHour,
                    'subtotal' => $subtotal,
                    'discount' => $discount,
                    'total' => $total,
                    'status' => $status,
                ]);

                // Create payment for paid/confirmed bookings
                if (in_array($status, ['paid', 'confirmed', 'completed'])) {
                    Payment::factory()->create([
                        'booking_id' => $booking->id,
                        'user_id' => $customer->id,
                        'amount' => $total,
                        'status' => 'paid',
                        'paid_at' => $booking->created_at->addHours(rand(1, 24)),
                    ]);
                }
            }
        }
    }

    /**
     * Create reviews
     */
    private function createReviews(): void
    {
        $this->command->info('Creating reviews...');

        $customers = User::where('role', 'customer')->get();
        $studios = Studio::all();

        $reviewComments = [
            'Tempatnya bagus banget! Equipment lengkap dan suara mantap.',
            'Studio yang nyaman untuk rekaman. recommended!',
            'Pelayanan ramah, fasilitas ok. worth it!',
            'Sound quality-nya juara. Pasti balik lagi.',
            'Lumayan lah, tapi bisa lebih bersih lagi.',
            'Harga sesuai dengan fasilitas yang didapat.',
            'Tempat favorit buat latihan band!',
            'Acoustic room-nya enak banget.',
            'Parking agak susah, tapi studio-nya oke.',
            'Cocok buat pemula yang mau mulai rekaman.',
        ];

        foreach ($customers->take(10) as $customer) {
            // Each customer reviews 1-3 studios
            $reviewCount = rand(1, 3);
            $reviewedStudios = $studios->random($reviewCount);
            
            foreach ($reviewedStudios as $studio) {
                Review::factory()->create([
                    'user_id' => $customer->id,
                    'studio_id' => $studio->id,
                    'rating' => rand(3, 5),
                    'comment' => $reviewComments[array_rand($reviewComments)],
                    'is_anonymous' => rand(1, 10) <= 2, // 20% anonymous
                ]);
            }
        }
    }

    /**
     * Create favorites
     */
    private function createFavorites(): void
    {
        $this->command->info('Creating favorites...');

        $customers = User::where('role', 'customer')->get();
        $studios = Studio::all();

        foreach ($customers as $customer) {
            // Each customer favorites 2-5 studios
            $favoriteCount = rand(2, 5);
            $favoriteStudios = $studios->random(min($favoriteCount, $studios->count()));
            
            foreach ($favoriteStudios as $studio) {
                Favorite::create([
                    'user_id' => $customer->id,
                    'studio_id' => $studio->id,
                ]);
            }
        }
    }

    /**
     * Create bands with members
     */
    private function createBands(): void
    {
        $this->command->info('Creating bands...');

        $customers = User::where('role', 'customer')->get();

        $bandNames = [
            'The Rockstars',
            'Melody Makers',
            'Sound Waves',
            'Rhythm Kings',
            'Echo Band',
            'Studio Session',
        ];

        foreach ($customers->take(4) as $index => $customer) {
            $band = Band::factory()->create([
                'owner_id' => $customer->id,
                'name' => $bandNames[$index % count($bandNames)],
            ]);

            // Add 2-4 members
            $memberCount = rand(2, 4);
            $potentialMembers = $customers->where('id', '!=', $customer->id)->random(min($memberCount, $customers->count() - 1));
            
            foreach ($potentialMembers as $memberIndex => $member) {
                BandMember::create([
                    'band_id' => $band->id,
                    'user_id' => $member->id,
                    'role' => $memberIndex === 0 ? 'owner' : 'member',
                    'status' => fake()->randomElement(['accepted', 'pending']),
                    'invited_at' => now()->subDays(rand(1, 30)),
                    'accepted_at' => fake()->randomElement([now()->subDays(rand(1, 20)), null]),
                ]);
            }
        }
    }

    /**
     * Create promos
     */
    private function createPromos(): void
    {
        $this->command->info('Creating promos...');

        $studios = Studio::all();

        $promoNames = [
            'New Year Special',
            'Weekend Discount',
            'Happy Hour',
            'Student Discount',
            'Loyal Customer',
        ];

        foreach ($studios->take(5) as $index => $studio) {
            Promo::factory()->create([
                'studio_id' => $studio->id,
                'name' => $promoNames[$index],
                'code' => strtoupper(Str::random(6)),
                'type' => $index % 2 == 0 ? 'percentage' : 'fixed',
                'value' => $index % 2 == 0 ? 10 : 25000,
                'start_date' => now(),
                'end_date' => now()->addMonth(),
                'is_active' => true,
            ]);
        }
    }

    /**
     * Create notifications
     */
    private function createNotifications(): void
    {
        $this->command->info('Creating notifications...');

        $users = User::all();

        $notificationTypes = [
            ['type' => 'booking', 'title' => 'Booking Confirmed', 'body' => 'Your booking has been confirmed!'],
            ['type' => 'payment', 'title' => 'Payment Received', 'body' => 'Your payment has been processed successfully.'],
            ['type' => 'promo', 'title' => 'New Promo Available', 'body' => 'Check out our new weekend discount!'],
            ['type' => 'system', 'title' => 'Welcome to StudioBook', 'body' => 'Thank you for joining StudioBook!'],
        ];

        foreach ($users->take(10) as $user) {
            // Each user gets 2-4 notifications
            $notificationCount = rand(2, 4);
            
            for ($i = 0; $i < $notificationCount; $i++) {
                $notification = $notificationTypes[array_rand($notificationTypes)];
                
                Notification::create([
                    'user_id' => $user->id,
                    'type' => $notification['type'],
                    'title' => $notification['title'],
                    'body' => $notification['body'],
                    'data' => ['user_id' => $user->id],
                    'is_read' => rand(1, 10) <= 6, // 60% read
                    'read_at' => rand(1, 10) <= 6 ? now()->subHours(rand(1, 48)) : null,
                ]);
            }
        }
    }
}
