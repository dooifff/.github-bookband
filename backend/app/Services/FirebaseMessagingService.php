<?php

namespace App\Services;

use App\Models\User;
use App\Models\Booking;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FirebaseMessagingService
{
    protected string $projectId;
    protected string $serviceAccountPath;

    public function __construct()
    {
        $this->projectId = config('services.firebase.project_id', '');
        $this->serviceAccountPath = config('services.firebase.credentials', '');
    }

    /**
     * Send push notification to a single device
     */
    public function sendToDevice(string $fcmToken, array $data): bool
    {
        try {
            $serverKey = config('services.firebase.server_key', '');
            
            if (empty($serverKey) || empty($fcmToken)) {
                Log::warning('FCM: Missing server key or token');
                return false;
            }

            $response = Http::withHeaders([
                'Authorization' => 'key=' . $serverKey,
                'Content-Type' => 'application/json',
            ])->post('https://fcm.googleapis.com/fcm/send', [
                'to' => $fcmToken,
                'notification' => [
                    'title' => $data['title'] ?? 'StudioBook',
                    'body' => $data['body'] ?? '',
                    'icon' => $data['icon'] ?? 'notification_icon',
                    'click_action' => $data['click_action'] ?? 'FLUTTER_NOTIFICATION_CLICK',
                ],
                'data' => $data['data'] ?? [],
                'priority' => 'high',
            ]);

            if ($response->successful()) {
                Log::info("FCM: Notification sent successfully to {$fcmToken}");
                return true;
            }

            Log::error("FCM: Failed to send notification - {$response->body()}");
            return false;
        } catch (\Exception $e) {
            Log::error("FCM: Error sending notification - {$e->getMessage()}");
            return false;
        }
    }

    /**
     * Send push notification to multiple devices
     */
    public function sendToMultiple(array $fcmTokens, array $data): int
    {
        try {
            $serverKey = config('services.firebase.server_key', '');
            
            if (empty($serverKey) || empty($fcmTokens)) {
                Log::warning('FCM: Missing server key or tokens');
                return 0;
            }

            $response = Http::withHeaders([
                'Authorization' => 'key=' . $serverKey,
                'Content-Type' => 'application/json',
            ])->post('https://fcm.googleapis.com/fcm/send', [
                'registration_ids' => $fcmTokens,
                'notification' => [
                    'title' => $data['title'] ?? 'StudioBook',
                    'body' => $data['body'] ?? '',
                    'icon' => $data['icon'] ?? 'notification_icon',
                    'click_action' => $data['click_action'] ?? 'FLUTTER_NOTIFICATION_CLICK',
                ],
                'data' => $data['data'] ?? [],
                'priority' => 'high',
            ]);

            if ($response->successful()) {
                $result = $response->json();
                $successCount = $result['success'] ?? 0;
                Log::info("FCM: Sent {$successCount} notifications successfully");
                return $successCount;
            }

            Log::error("FCM: Failed to send notifications - {$response->body()}");
            return 0;
        } catch (\Exception $e) {
            Log::error("FCM: Error sending notifications - {$e->getMessage()}");
            return 0;
        }
    }

    /**
     * Send booking confirmation push notification
     */
    public function sendBookingConfirmation(Booking $booking): void
    {
        $user = $booking->user;
        
        if (!$user->fcm_token) {
            Log::info("FCM: User {$user->id} has no FCM token");
            return;
        }

        $data = [
            'title' => '✅ Booking Dikonfirmasi',
            'body' => "Booking {$booking->booking_code} telah dikonfirmasi. {$booking->date}, {$booking->start_time}-{$booking->end_time}",
            'data' => [
                'type' => 'booking_confirmed',
                'booking_id' => $booking->id,
                'booking_code' => $booking->booking_code,
                'screen' => '/bookings/{$booking->booking_code}',
            ],
        ];

        $this->sendToDevice($user->fcm_token, $data);
    }

    /**
     * Send booking reminder push notification
     */
    public function sendBookingReminder(Booking $booking, string $type): void
    {
        $user = $booking->user;
        
        if (!$user->fcm_token) {
            Log::info("FCM: User {$user->id} has no FCM token");
            return;
        }

        $title = match($type) {
            '1_hour' => '⏰ Booking dalam 1 Jam',
            'tomorrow' => '📅 Booking Besok',
            default => '🔔 Pengingat Booking',
        };

        $body = match($type) {
            '1_hour' => "Booking di {$booking->studio->name} akan dimulai dalam 1 jam",
            'tomorrow' => "Anda memiliki booking di {$booking->studio->name} besok",
            default => "Pengingat untuk booking {$booking->booking_code}",
        };

        $data = [
            'title' => $title,
            'body' => $body,
            'data' => [
                'type' => 'booking_reminder',
                'booking_id' => $booking->id,
                'booking_code' => $booking->booking_code,
                'reminder_type' => $type,
                'screen' => '/bookings/{$booking->booking_code}',
            ],
        ];

        $this->sendToDevice($user->fcm_token, $data);
    }

    /**
     * Send payment reminder push notification
     */
    public function sendPaymentReminder(Booking $booking): void
    {
        $user = $booking->user;
        
        if (!$user->fcm_token) {
            Log::info("FCM: User {$user->id} has no FCM token");
            return;
        }

        $data = [
            'title' => '💳 Pengingat Pembayaran',
            'body' => "Booking {$booking->booking_code} masih menunggu pembayaran. Selesaikan sekarang!",
            'data' => [
                'type' => 'payment_reminder',
                'booking_id' => $booking->id,
                'booking_code' => $booking->booking_code,
                'screen' => '/bookings/{$booking->booking_code}/payment',
            ],
        ];

        $this->sendToDevice($user->fcm_token, $data);
    }

    /**
     * Send booking cancellation push notification
     */
    public function sendBookingCancellation(Booking $booking): void
    {
        $user = $booking->user;
        
        if (!$user->fcm_token) {
            Log::info("FCM: User {$user->id} has no FCM token");
            return;
        }

        $data = [
            'title' => '❌ Booking Dibatalkan',
            'body' => "Booking {$booking->booking_code} telah dibatalkan.",
            'data' => [
                'type' => 'booking_cancelled',
                'booking_id' => $booking->id,
                'booking_code' => $booking->booking_code,
                'screen' => '/bookings',
            ],
        ];

        $this->sendToDevice($user->fcm_token, $data);
    }

    /**
     * Send new booking notification to studio owner
     */
    public function sendNewBookingToOwner(Booking $booking): void
    {
        $owner = $booking->studio->owner;
        
        if (!$owner->fcm_token) {
            Log::info("FCM: Owner {$owner->id} has no FCM token");
            return;
        }

        $data = [
            'title' => '🆕 Booking Baru',
            'body' => "Booking baru dari {$booking->user->name} di {$booking->room->name} ({$booking->date})",
            'data' => [
                'type' => 'new_booking',
                'booking_id' => $booking->id,
                'booking_code' => $booking->booking_code,
                'studio_id' => $booking->studio_id,
                'screen' => '/owner/bookings',
            ],
        ];

        $this->sendToDevice($owner->fcm_token, $data);
    }

    /**
     * Store FCM token for user
     */
    public function storeFcmToken(User $user, string $token): bool
    {
        try {
            $user->update(['fcm_token' => $token]);
            Log::info("FCM: Token stored for user {$user->id}");
            return true;
        } catch (\Exception $e) {
            Log::error("FCM: Failed to store token - {$e->getMessage()}");
            return false;
        }
    }

    /**
     * Remove FCM token for user
     */
    public function removeFcmToken(User $user): bool
    {
        try {
            $user->update(['fcm_token' => null]);
            Log::info("FCM: Token removed for user {$user->id}");
            return true;
        } catch (\Exception $e) {
            Log::error("FCM: Failed to remove token - {$e->getMessage()}");
            return false;
        }
    }
}
