<?php

namespace App\Services;

use App\Models\Booking;
use App\Models\User;
use App\Notifications\BookingReminderNotification;
use App\Notifications\BookingStatusNotification;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;

class BookingReminderService
{
    /**
     * Send reminders for bookings happening in the next hour
     */
    public function sendUpcomingBookingReminders(): void
    {
        $now = Carbon::now();
        $oneHourLater = $now->copy()->addHour();

        // Find bookings happening in the next hour that haven't been reminded
        $bookings = Booking::with(['user', 'studio', 'room'])
            ->where('status', 'confirmed')
            ->where('date', $now->toDateString())
            ->whereBetween('start_time', [
                $now->format('H:i:s'),
                $oneHourLater->format('H:i:s'),
            ])
            ->where('reminder_sent_at', null)
            ->get();

        foreach ($bookings as $booking) {
            $this->sendReminder($booking, '1_hour');
        }

        Log::info("Sent " . $bookings->count() . " booking reminders for next hour");
    }

    /**
     * Send reminders for bookings happening tomorrow
     */
    public function sendTomorrowBookingReminders(): void
    {
        $tomorrow = Carbon::tomorrow();

        // Find bookings for tomorrow that haven't been reminded
        $bookings = Booking::with(['user', 'studio', 'room'])
            ->where('status', 'confirmed')
            ->where('date', $tomorrow->toDateString())
            ->whereNull('reminder_sent_at')
            ->get();

        foreach ($bookings as $booking) {
            $this->sendReminder($booking, 'tomorrow');
        }

        Log::info("Sent " . $bookings->count() . " booking reminders for tomorrow");
    }

    /**
     * Send reminder notification to user
     */
    protected function sendReminder(Booking $booking, string $type): void
    {
        try {
            $user = $booking->user;
            
            // Determine reminder message based on type
            $title = match($type) {
                '1_hour' => 'Booking dalam 1 Jam',
                'tomorrow' => 'Booking Besok',
                default => 'Pengingat Booking',
            };

            $message = match($type) {
                '1_hour' => "Booking Anda di {$booking->studio->name} - {$booking->room->name} akan dimulai dalam 1 jam ({$booking->start_time})",
                'tomorrow' => "Anda memiliki booking di {$booking->studio->name} - {$booking->room->name} besok ({$booking->start_time})",
                default => "Pengingat untuk booking {$booking->booking_code}",
            };

            // Send notification
            $user->notify(new BookingReminderNotification(
                booking: $booking,
                title: $title,
                message: $message,
                type: $type
            ));

            // Update reminder sent timestamp
            $booking->update(['reminder_sent_at' => Carbon::now()]);

            Log::info("Reminder sent to {$user->email} for booking {$booking->booking_code}");
        } catch (\Exception $e) {
            Log::error("Failed to send reminder for booking {$booking->booking_code}: {$e->getMessage()}");
        }
    }

    /**
     * Send booking confirmation notification
     */
    public function sendBookingConfirmation(Booking $booking): void
    {
        try {
            $user = $booking->user;

            $user->notify(new BookingStatusNotification(
                booking: $booking,
                status: 'confirmed',
                title: 'Booking Dikonfirmasi',
                message: "Booking {$booking->booking_code} telah dikonfirmasi. Tanggal: {$booking->date}, Waktu: {$booking->start_time} - {$booking->end_time}"
            ));

            Log::info("Confirmation sent to {$user->email} for booking {$booking->booking_code}");
        } catch (\Exception $e) {
            Log::error("Failed to send confirmation for booking {$booking->booking_code}: {$e->getMessage()}");
        }
    }

    /**
     * Send booking cancellation notification
     */
    public function sendBookingCancellation(Booking $booking, string $reason = ''): void
    {
        try {
            $user = $booking->user;

            $message = "Booking {$booking->booking_code} telah dibatalkan.";
            if ($reason) {
                $message .= " Alasan: {$reason}";
            }

            $user->notify(new BookingStatusNotification(
                booking: $booking,
                status: 'cancelled',
                title: 'Booking Dibatalkan',
                message: $message
            ));

            Log::info("Cancellation sent to {$user->email} for booking {$booking->booking_code}");
        } catch (\Exception $e) {
            Log::error("Failed to send cancellation for booking {$booking->booking_code}: {$e->getMessage()}");
        }
    }

    /**
     * Send payment reminder for pending bookings
     */
    public function sendPaymentReminders(): void
    {
        // Find bookings awaiting payment for more than 1 hour
        $bookings = Booking::with(['user', 'studio', 'room', 'payment'])
            ->where('status', 'awaiting_payment')
            ->where('created_at', '<', Carbon::now()->subHour())
            ->whereNull('payment_reminder_sent_at')
            ->get();

        foreach ($bookings as $booking) {
            try {
                $user = $booking->user;

                $user->notify(new BookingStatusNotification(
                    booking: $booking,
                    status: 'payment_pending',
                    title: 'Pengingat Pembayaran',
                    message: "Booking {$booking->booking_code} masih menunggu pembayaran. Silakan selesaikan pembayaran sebelum booking dibatalkan otomatis."
                ));

                $booking->update(['payment_reminder_sent_at' => Carbon::now()]);

                Log::info("Payment reminder sent to {$user->email} for booking {$booking->booking_code}");
            } catch (\Exception $e) {
                Log::error("Failed to send payment reminder for booking {$booking->booking_code}: {$e->getMessage()}");
            }
        }
    }

    /**
     * Auto-cancel expired bookings (awaiting payment for more than 2 hours)
     */
    public function autoCancelExpiredBookings(): int
    {
        $expiredBookings = Booking::with(['user', 'studio', 'room'])
            ->where('status', 'awaiting_payment')
            ->where('created_at', '<', Carbon::now()->subHours(2))
            ->get();

        $count = 0;

        foreach ($expiredBookings as $booking) {
            $booking->update([
                'status' => 'cancelled',
                'cancelled_at' => Carbon::now(),
                'cancellation_reason' => 'Pembayaran tidak diselesaikan dalam waktu 2 jam',
            ]);

            // Release the room slot
            // The schedule will be automatically available again

            // Send cancellation notification
            $this->sendBookingCancellation($booking, 'Pembayaran tidak diselesaikan dalam waktu 2 jam');

            $count++;
        }

        Log::info("Auto-cancelled {$count} expired bookings");

        return $count;
    }
}
