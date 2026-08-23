<?php

namespace App\Notifications;

use App\Models\Booking;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class BookingReminderNotification extends Notification implements ShouldQueue
{
    use Queueable;

    protected Booking $booking;
    protected string $title;
    protected string $message;
    protected string $type;

    public function __construct(
        Booking $booking,
        string $title,
        string $message,
        string $type = 'general'
    ) {
        $this->booking = $booking;
        $this->title = $title;
        $this->message = $message;
        $this->type = $type;
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
            ->line($this->message)
            ->line("Kode Booking: {$this->booking->booking_code}")
            ->line("Studio: {$this->booking->studio->name}")
            ->line("Ruangan: {$this->booking->room->name}")
            ->line("Tanggal: {$this->booking->date}")
            ->line("Waktu: {$this->booking->start_time} - {$this->booking->end_time}");

        if ($this->type === '1_hour') {
            $mailMessage->line('⏰ Booking Anda akan dimulai dalam 1 jam!')
                ->action('Lihat Booking', url("/bookings/{$this->booking->booking_code}"));
        } elseif ($this->type === 'tomorrow') {
            $mailMessage->line('📅 Booking Anda adalah besok!')
                ->action('Lihat Detail', url("/bookings/{$this->booking->booking_code}"));
        }

        return $mailMessage
            ->line('Terima kasih telah menggunakan StudioBook!')
            ->line('🎵 Selamat bermain musik!');
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
            'type' => 'booking_reminder',
            'title' => $this->title,
            'message' => $this->message,
            'booking_id' => $this->booking->id,
            'booking_code' => $this->booking->booking_code,
            'studio_name' => $this->booking->studio->name,
            'room_name' => $this->booking->room->name,
            'booking_date' => $this->booking->date,
            'start_time' => $this->booking->start_time,
            'end_time' => $this->booking->end_time,
            'reminder_type' => $this->type,
            'created_at' => now(),
        ];
    }
}
