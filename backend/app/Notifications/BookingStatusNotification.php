<?php

namespace App\Notifications;

use App\Models\Booking;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class BookingStatusNotification extends Notification implements ShouldQueue
{
    use Queueable;

    protected Booking $booking;
    protected string $status;
    protected string $title;
    protected string $message;

    public function __construct(
        Booking $booking,
        string $status,
        string $title,
        string $message
    ) {
        $this->booking = $booking;
        $this->status = $status;
        $this->title = $title;
        $this->message = $message;
    }

    /**
     * Get the notification's delivery channels.
     *
     * @return array<int, string>
     */
    public function via(object $notifiable): array
    {
        return ['mail', 'database'];
    }

    /**
     * Get the mail representation of the notification.
     */
    public function toMail(object $notifiable): MailMessage
    {
        $mailMessage = (new MailMessage)
            ->subject("🎸 StudioBook - {$this->title}")
            ->greeting("Halo {$notifiable->name}!")
            ->line($this->message);

        // Add status-specific styling
        return match($this->status) {
            'confirmed' => $mailMessage
                ->line('✅ Booking Anda telah dikonfirmasi oleh pemilik studio.')
                ->line("Studio: {$this->booking->studio->name}")
                ->line("Ruangan: {$this->booking->room->name}")
                ->line("Tanggal: {$this->booking->date}")
                ->line("Waktu: {$this->booking->start_time} - {$this->booking->end_time}")
                ->action('Lihat Booking', url("/bookings/{$this->booking->booking_code}"))
                ->line('🎵 Siap untuk bermain musik!'),

            'cancelled' => $mailMessage
                ->line('❌ Booking Anda telah dibatalkan.')
                ->when($this->booking->cancellation_reason, function ($mail) {
                    return $mail->line("Alasan: {$this->booking->cancellation_reason}");
                })
                ->action('Buat Booking Baru', url('/studios'))
                ->line('Hubungi kami jika ada pertanyaan.'),

            'payment_pending' => $mailMessage
                ->line('💳 Booking Anda menunggu pembayaran.')
                ->line("Silakan selesaikan pembayaran sebelum booking dibatalkan otomatis.")
                ->action('Bayar Sekarang', url("/bookings/{$this->booking->booking_code}/payment"))
                ->line('⏰ Pembayaran harus diselesaikan dalam 2 jam.'),

            'completed' => $mailMessage
                ->line('🎉 Booking telah selesai!')
                ->line('Terima kasih telah menggunakan StudioBook.')
                ->action('Beri Ulasan', url("/bookings/{$this->booking->booking_code}/review"))
                ->line('Bagikan pengalaman Anda dengan memberikan ulasan!'),

            default => $mailMessage
                ->action('Lihat Detail', url("/bookings/{$this->booking->booking_code}")),
        };
    }

    /**
     * Get the array representation of the notification.
     *
     * @return array<string, mixed>
     */
    public function toArray(object $notifiable): array
    {
        return [
            'id' => $this->id,
            'type' => 'booking_status',
            'title' => $this->title,
            'message' => $this->message,
            'status' => $this->status,
            'booking_id' => $this->booking->id,
            'booking_code' => $this->booking->booking_code,
            'studio_name' => $this->booking->studio->name,
            'room_name' => $this->booking->room->name,
            'booking_date' => $this->booking->date,
            'start_time' => $this->booking->start_time,
            'end_time' => $this->booking->end_time,
            'total_amount' => $this->booking->total,
            'created_at' => now(),
        ];
    }
}
