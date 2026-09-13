<?php

namespace App\Console\Commands;

use App\Services\StudioSubscriptionService;
use Illuminate\Console\Command;

class CheckStudioSubscriptions extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'studio-subscription:check {--dry-run : Tampilkan ringkasan tanpa mengirim email / menghapus studio}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Cek masa berlangganan studio: kirim peringatan email bertahap dan hapus studio yang tidak memperpanjang';

    public function handle(): int
    {
        $service = new StudioSubscriptionService();

        try {
            if (!$service->isEnabled()) {
                $this->warn('⏸️  Penegakan langganan dinonaktifkan (SUBSCRIPTION_ENFORCEMENT_ENABLED=false).');
                return Command::SUCCESS;
            }

            if ($this->option('dry-run')) {
                $newlyExpired = $service->markExpired();
                $this->info("📋 DRY RUN - tidak ada email dikirim / studio dihapus");
                $this->info("   - Studio baru berstatus expired : {$newlyExpired}");
                $this->info("   - Jalankan tanpa --dry-run untuk memproses peringatan & penghapusan.");
                return Command::SUCCESS;
            }

            $stats = $service->run();

            $this->info('✅ Pemeriksaan langganan studio selesai:');
            $this->info("   - Baru expired                 : {$stats['newly_expired']}");
            $this->info("   - Peringatan 1 dikirim         : {$stats['first_warnings_sent']}");
            $this->info("   - Peringatan 2 dikirim         : {$stats['second_warnings_sent']}");
            $this->info("   - Studio dihapus otomatis      : {$stats['deleted']}");
            $this->info("   - Dihapus ditunda (ada booking): {$stats['deletion_blocked_by_bookings']}");

            return Command::SUCCESS;
        } catch (\Exception $e) {
            $this->error("❌ Error: {$e->getMessage()}");

            return Command::FAILURE;
        }
    }
}
