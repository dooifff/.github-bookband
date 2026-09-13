<?php

namespace App\Services;

use App\Models\Booking;
use App\Models\Studio;
use App\Models\StudioRoom;
use App\Models\BlockedSchedule;
use App\Models\OpeningHour;
use App\Models\Promo;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;
use Carbon\CarbonPeriod;
use InvalidArgumentException;

class BookingService
{
    /**
     * Create a new booking with full validation and transaction safety.
     * 
     * Rules from concept:
     * - Backend is the source of truth for availability
     * - Prevent overlapping bookings
     * - Prevent double booking on concurrent requests
     * - Use database transaction
     * - Validate studio, room, status, date, operating hours, blocked schedule, duration, overlap
     * - Calculate subtotal, discount, total on server
     * - Don't trust price from client
     * 
     * @throws InvalidArgumentException
     */
    public function createBooking(array $data, User $user): Booking
    {
        return DB::transaction(function () use ($data, $user) {
            // 1. Find and validate studio
            $studio = Studio::where('id', $data['studio_id'])
                ->where('is_active', true)
                ->where('is_verified', true)
                ->lockForUpdate()
                ->first();
            
            if (!$studio) {
                throw new InvalidArgumentException('Studio tidak ditemukan atau tidak aktif');
            }

            // 2. Find and validate room
            $room = StudioRoom::where('id', $data['room_id'])
                ->where('studio_id', $studio->id)
                ->where('is_active', true)
                ->lockForUpdate()
                ->first();
            
            if (!$room) {
                throw new InvalidArgumentException('Ruangan tidak ditemukan atau tidak aktif');
            }

            // 3. Parse booking date and times
            $bookingDate = Carbon::parse($data['date']);
            $startTime = Carbon::parse($data['start_time']);
            $endTime = Carbon::parse($data['end_time']);
            
            // Validate date is not in the past
            if ($bookingDate->isPast()) {
                throw new InvalidArgumentException('Tanggal booking tidak boleh di masa lalu');
            }

            // Validate end time is after start time
            if ($endTime->lte($startTime)) {
                throw new InvalidArgumentException('Jam selesai harus setelah jam mulai');
            }

            // 4. Check if studio is open on this day
            $this->validateStudioHours($studio, $bookingDate, $startTime, $endTime);

            // 5. Check for blocked schedules
            $this->validateBlockedSchedule($studio, $room->id, $bookingDate, $startTime, $endTime);

            // 6. Check for overlapping bookings (with row-level locking)
            $this->validateOverlappingBookings($room->id, $bookingDate, $startTime, $endTime);

            // 7. Calculate duration and price server-side
            $durationInMinutes = $startTime->diffInMinutes($endTime);
            $durationInHours = $durationInMinutes / 60;
            
            $pricePerHour = $room->price_per_hour;
            $subtotal = $pricePerHour * $durationInHours;

            // 8. Apply promo/discount if provided
            $discount = 0;
            $promoId = null;
            
            if (!empty($data['promo_code'])) {
                $promoResult = $this->applyPromo($data['promo_code'], $subtotal, $bookingDate);
                $discount = $promoResult['discount'];
                $promoId = $promoResult['promo_id'];
            }

            // 9. Calculate total
            $total = $subtotal - $discount;
            
            if ($total < 0) {
                $total = 0;
            }

            // 10. Create the booking
            $booking = Booking::create([
                'user_id' => $user->id,
                'studio_id' => $studio->id,
                'room_id' => $room->id,
                'band_id' => $data['band_id'] ?? null,
                'date' => $bookingDate->toDateString(),
                'start_time' => $startTime->format('H:i:s'),
                'end_time' => $endTime->format('H:i:s'),
                'duration_hours' => $durationInMinutes / 60,
                'price_per_hour' => $pricePerHour,
                'subtotal' => $subtotal,
                'discount' => $discount,
                'total' => $total,
                'promo_code' => $data['promo_code'] ?? null,
                'status' => 'pending',
                'notes' => $data['notes'] ?? null,
                'booking_code' => $this->generateBookingCode(),
            ]);

            // 11. Update promo usage count if applicable
            if ($promoId) {
                Promo::where('id', $promoId)->increment('usage_count');
            }

            return $booking->load(['studio', 'room']);
        });
    }

    /**
     * Validate studio opening hours
     */
    private function validateStudioHours(Studio $studio, Carbon $date, Carbon $startTime, Carbon $endTime): void
    {
        $dayOfWeek = $date->dayOfWeekIso; // 1=Monday, 7=Sunday
        
        $openingHour = OpeningHour::where('studio_id', $studio->id)
            ->where('day_of_week', $dayOfWeek)
            ->first();
        
        if (!$openingHour || $openingHour->is_closed) {
            throw new InvalidArgumentException('Studio tutup pada hari tersebut');
        }

        $openTime = Carbon::parse($openingHour->open_time);
        $closeTime = Carbon::parse($openingHour->close_time);

        if ($startTime->lt($openTime) || $endTime->gt($closeTime)) {
            throw new InvalidArgumentException(
                "Jam operasional studio: {$openingHour->open_time} - {$openingHour->close_time}"
            );
        }
    }

    /**
     * Validate no blocked schedules conflict
     */
    private function validateBlockedSchedule(Studio $studio, $roomId, Carbon $date, Carbon $startTime, Carbon $endTime): void
    {
        $dateString = $date->toDateString();

        $hasConflict = BlockedSchedule::where('studio_id', $studio->id)
            ->where(function ($query) use ($roomId) {
                $query->where('room_id', $roomId)
                    ->orWhereNull('room_id'); // null means whole studio blocked
            })
            ->whereDate('date', $dateString)
            ->where(function ($query) use ($startTime, $endTime) {
                // All-day block for this date
                $query->where('all_day', true)
                    // Or time-range block that overlaps
                    ->orWhere(function ($q) use ($startTime, $endTime) {
                        $q->where('all_day', false)
                          ->where('start_time', '<', $endTime->format('H:i:s'))
                          ->where('end_time', '>', $startTime->format('H:i:s'));
                    });
            })
            ->exists();

        if ($hasConflict) {
            throw new InvalidArgumentException('Jadwal bentrok dengan jadwal yang diblokir');
        }
    }

    /**
     * Validate no overlapping bookings exist
     */
    private function validateOverlappingBookings($roomId, Carbon $date, Carbon $startTime, Carbon $endTime): void
    {
        $hasOverlap = Booking::where('room_id', $roomId)
            ->whereDate('date', $date->toDateString())
            ->whereNotIn('status', ['cancelled', 'expired', 'failed'])
            ->where(function ($query) use ($startTime, $endTime) {
                // Overlap condition: existing.start < new.end AND existing.end > new.start
                $query->where(function ($q) use ($startTime, $endTime) {
                    $q->where('start_time', '<', $endTime->format('H:i:s'))
                      ->where('end_time', '>', $startTime->format('H:i:s'));
                });
            })
            ->lockForUpdate()
            ->exists();

        if ($hasOverlap) {
            throw new InvalidArgumentException('Ruangan sudah dibooking pada jam tersebut');
        }
    }

    /**
     * Apply promo code and calculate discount
     */
    private function applyPromo(string $promoCode, float $subtotal, Carbon $date): array
    {
        $promo = Promo::where('code', $promoCode)
            ->where('is_active', true)
            ->where('start_date', '<=', $date)
            ->where('end_date', '>=', $date)
            ->first();

        if (!$promo) {
            throw new InvalidArgumentException('Kode promo tidak valid atau sudah tidak berlaku');
        }

        // Check usage limit
        if ($promo->usage_limit && $promo->usage_count >= $promo->usage_limit) {
            throw new InvalidArgumentException('Kode promo sudah mencapai batas penggunaan');
        }

        // Check minimum booking amount
        if ($promo->min_booking_amount && $subtotal < $promo->min_booking_amount) {
            throw new InvalidArgumentException(
                "Minimal booking Rp " . number_format($promo->min_booking_amount, 0, ',', '.') . " untuk menggunakan promo ini"
            );
        }

        // Calculate discount
        $discount = 0;
        
        if ($promo->type === 'percentage') {
            $discount = ($subtotal * $promo->value) / 100;
            
            // Apply max discount if set
            if ($promo->max_discount && $discount > $promo->max_discount) {
                $discount = $promo->max_discount;
            }
        } elseif ($promo->type === 'fixed') {
            $discount = $promo->value;
        }

        // Ensure discount doesn't exceed subtotal
        if ($discount > $subtotal) {
            $discount = $subtotal;
        }

        return [
            'discount' => $discount,
            'promo_id' => $promo->id,
        ];
    }

    /**
     * Generate unique booking code
     */
    private function generateBookingCode(): string
    {
        $prefix = 'SB';
        $date = now()->format('ymd');
        $random = strtoupper(substr(uniqid(), -6));
        
        return "{$prefix}{$date}{$random}";
    }

    /**
     * Cancel a booking
     */
    public function cancelBooking(Booking $booking, User $user, ?string $reason = null): Booking
    {
        // Verify ownership
        if ($booking->user_id !== $user->id) {
            throw new InvalidArgumentException('Anda tidak memiliki akses untuk membatalkan booking ini');
        }

        // Check if booking can be cancelled
        if (!in_array($booking->status, ['pending', 'awaiting_payment'])) {
            throw new InvalidArgumentException('Booking tidak dapat dibatalkan pada status saat ini');
        }

        $booking = DB::transaction(function () use ($booking, $reason) {
            $booking->update([
                'status' => 'cancelled',
                'cancel_reason' => $reason,
                'cancelled_at' => now(),
            ]);

            // Decrease promo usage if applicable
            if ($booking->promo_code) {
                Promo::where('code', $booking->promo_code)->decrement('usage_count');
            }

            return $booking->fresh();
        });

        // Send notification to customer
        try {
            \App\Models\Notification::create([
                'user_id' => $booking->user_id,
                'type' => 'booking',
                'title' => 'Booking Dibatalkan',
                'body' => "Booking {$booking->booking_code} telah dibatalkan." . ($reason ? " Alasan: {$reason}" : ''),
                'data' => [
                    'booking_id' => $booking->id,
                    'booking_code' => $booking->booking_code,
                    'status' => 'cancelled',
                    'reason' => $reason,
                ],
            ]);
        } catch (\Exception $e) {
            // Notification failure should not block the booking cancellation
        }

        return $booking;
    }

    /**
     * Confirm a booking (after payment)
     */
    public function confirmBooking(Booking $booking): Booking
    {
        $booking = DB::transaction(function () use ($booking) {
            $booking->update([
                'status' => 'confirmed',
                'confirmed_at' => now(),
            ]);

            return $booking->fresh();
        });

        // Send notification to customer
        try {
            \App\Models\Notification::create([
                'user_id' => $booking->user_id,
                'type' => 'booking',
                'title' => 'Booking Dikonfirmasi',
                'body' => "Booking {$booking->booking_code} telah dikonfirmasi oleh pemilik studio.",
                'data' => [
                    'booking_id' => $booking->id,
                    'booking_code' => $booking->booking_code,
                    'status' => 'confirmed',
                ],
            ]);
        } catch (\Exception $e) {
            // Notification failure should not block the booking confirmation
        }

        return $booking;
    }

    /**
     * Complete a booking
     */
    public function completeBooking(Booking $booking): Booking
    {
        return DB::transaction(function () use ($booking) {
            $booking->update([
                'status' => 'completed',
                'completed_at' => now(),
            ]);

            return $booking->fresh();
        });
    }

    /**
     * Get user's bookings with filters
     */
    public function getUserBookings(User $user, ?string $status = null)
    {
        $query = Booking::where('user_id', $user->id)
            ->with(['studio', 'room', 'payment']);

        if ($status) {
            $query->where('status', $status);
        }

        return $query->orderBy('date', 'desc')
            ->orderBy('start_time', 'desc')
            ->paginate(15);
    }

    /**
     * Get owner's studio bookings
     */
    public function getOwnerBookings(User $owner, ?string $status = null)
    {
        $studioIds = $owner->ownedStudios()->pluck('id');

        $query = Booking::whereIn('studio_id', $studioIds)
            ->with(['user', 'studio', 'room', 'payment']);

        if ($status) {
            $query->where('status', $status);
        }

        return $query->orderBy('date', 'desc')
            ->orderBy('start_time', 'desc')
            ->paginate(15);
    }
}
