<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Services\EmailReportService;

class SendPerformanceReports extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'performance:send-reports 
                            {--type=weekly : Report type (daily, weekly, monthly)} 
                            {--recipient= : Specific recipient email}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Send performance reports via email';

    /**
     * Execute the console command.
     */
    public function handle(EmailReportService $emailService)
    {
        $type = $this->option('type');
        $recipient = $this->option('recipient');

        $this->info("Sending {$type} performance report...");

        switch ($type) {
            case 'daily':
                if (!$recipient) {
                    $this->error('Daily report requires --recipient option');
                    return 1;
                }
                $success = $emailService->sendDailySummary($recipient);
                break;

            case 'weekly':
                $results = $emailService->sendWeeklyReport();
                $this->info("Sent to {$results['sent']} recipients, {$results['failed']} failed");
                return $results['failed'] > 0 ? 1 : 0;

            case 'monthly':
                if (!$recipient) {
                    $this->error('Monthly report requires --recipient option');
                    return 1;
                }
                $success = $emailService->sendMonthlyReport($recipient);
                break;

            default:
                $this->error("Unknown report type: {$type}");
                return 1;
        }

        if ($success) {
            $this->info("✅ Report sent successfully to {$recipient}");
            return 0;
        } else {
            $this->error("❌ Failed to send report to {$recipient}");
            return 1;
        }
    }
}
