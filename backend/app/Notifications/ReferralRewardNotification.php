<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class ReferralRewardNotification extends Notification implements ShouldQueue
{
    use Queueable;

    protected string $type;
    protected string $message;
    protected int $referredUserId;

    public function __construct(
        string $type,
        string $message,
        int $referredUserId
    ) {
        $this->type = $type;
        $this->message = $message;
        $this->referredUserId = $referredUserId;
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
        return (new MailMessage)
            ->subject('🎁 StudioBook - Reward Referral')
            ->greeting("Halo {$notifiable->name}!")
            ->line($this->message)
            ->line('Terima kasih telah menggunakan kode referral kami!')
            ->line('Kredit Anda akan otomatis ditambahkan ke akun.')
            ->action('Lihat Saldo', url('/profile'))
            ->line('Tetap undang teman-temanmu untuk mendapatkan lebih banyak reward!');
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
            'type' => 'referral_reward',
            'title' => 'Reward Referral',
            'message' => $this->message,
            'referred_user_id' => $this->referredUserId,
            'created_at' => now(),
        ];
    }
}
