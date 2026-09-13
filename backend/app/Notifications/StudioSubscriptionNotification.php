<?php

namespace App\Notifications;

use App\Models\Studio;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class StudioSubscriptionNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public Studio $studio;
    public string $stage;

    /**
     * @param string $stage first_warning | second_warning | deleted
     */
    public function __construct(Studio $studio, string $stage)
    {
        $this->studio = $studio;
        $this->stage = $stage;
    }

    public function via(object $notifiable): array
    {
        return ['mail', 'database'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $studio = $this->studio;
        $expiredAt = optional($studio->subscription_expires_at)->format('d M Y');
        $deleteAt = optional($studio->subscription_expires_at)
            ->copy()
            ->addDays((int) config('subscription.delete_days', 7))
            ->format('d M Y');
        $ownerUrl = url('/owner/studios');

        return match ($this->stage) {
            'first_warning' => (new MailMessage)
                ->subject("⏰ StudioBook - Peringatan 1: Langganan Studio \"{$studio->name}\" Telah Berakhir")
                ->greeting("Halo {$notifiable->name}!")
                ->line("Masa berlangganan studio \"{$studio->name}\" telah berakhir pada **{$expiredAt}**.")
                ->line('Mohon segera perpanjang langganan Anda agar studio tetap tampil dan dapat menerima pemesanan dari pelanggan.')
                ->action('Perpanjang Langganan', $ownerUrl)
                ->line('Jika langganan tidak diperpanjang, Anda akan menerima peringatan lanjutan dan studio berisiko dihapus otomatis dari platform.')
                ->line('Terima kasih telah menjadi bagian dari StudioBook!'),

            'second_warning' => (new MailMessage)
                ->subject("⚠️ StudioBook - Peringatan Terakhir: Studio \"{$studio->name}\" Akan Dihapus")
                ->greeting("Halo {$notifiable->name}!")
                ->line("Ini adalah peringatan **kedua dan terakhir**. Masa berlangganan studio \"{$studio->name}\" telah berakhir sejak **{$expiredAt}** dan kami belum menerima konfirmasi perpanjangan dari Anda.")
                ->line('Kami mohon untuk segera memperpanjang langganan melalui halaman studio Anda. Selama langganan tidak aktif, studio tidak akan tampil di pencarian pelanggan sehingga Anda berpotensi kehilangan pemesanan.')
                ->line("Apabila sampai tanggal **{$deleteAt}** kami masih belum menerima respons atau perpanjangan, studio Anda beserta data terkait akan **dihapus otomatis** dari platform tanpa pemberitahuan lebih lanjut.")
                ->action('Perpanjang Sekarang', $ownerUrl)
                ->line('Jika Anda merasa ini adalah kesalahan atau memiliki kendala pembayaran, segera hubungi tim kami agar kami dapat membantu Anda.'),

            default => (new MailMessage)
                ->subject("🗑️ StudioBook - Studio \"{$studio->name}\" Telah Dihapus")
                ->greeting("Halo {$notifiable->name}!")
                ->line("Studio \"{$studio->name}\" telah **dihapus otomatis** dari platform karena masa berlangganan tidak diperpanjang dan kami tidak menerima respons hingga batas waktu yang ditentukan.")
                ->line('Data studio Anda masih dapat dipulihkan dalam waktu tertentu. Silakan hubungi tim dukungan StudioBook sesegera mungkin jika Anda ingin mengaktifkan kembali studio tersebut.')
                ->action('Hubungi Tim Kami', $ownerUrl)
                ->line('Kami sangat menghargai Anda dan berharap dapat bekerja sama kembali di masa mendatang.'),
        };
    }

    public function toArray(object $notifiable): array
    {
        return [
            'id' => $this->id,
            'type' => 'studio_subscription',
            'stage' => $this->stage,
            'title' => $this->stage === 'first_warning'
                ? "Peringatan 1: Langganan \"{$this->studio->name}\" berakhir"
                : ($this->stage === 'second_warning'
                    ? "Peringatan terakhir: \"{$this->studio->name}\" akan dihapus"
                    : "Studio \"{$this->studio->name}\" telah dihapus"),
            'message' => match ($this->stage) {
                'first_warning' => "Masa berlangganan studio \"{$this->studio->name}\" telah berakhir. Segera perpanjang agar studio tetap tampil.",
                'second_warning' => "Studio \"{$this->studio->name}\" akan dihapus otomatis jika langganan tidak segera diperpanjang.",
                default => "Studio \"{$this->studio->name}\" telah dihapus otomatis karena masa berlangganan berakhir.",
            },
            'studio_id' => $this->studio->id,
            'studio_name' => $this->studio->name,
            'expires_at' => optional($this->studio->subscription_expires_at)->toISOString(),
            'created_at' => now(),
        ];
    }
}
