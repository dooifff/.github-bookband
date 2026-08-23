<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Services\EmailReportService;
use App\Services\PerformanceHistoryService;
use App\Services\PerformanceAlertService;
use Illuminate\Support\Facades\Log;

class WeeklyPerformanceReport extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'performance:weekly-report 
                            {--recipients= : Comma-separated list of recipients} 
                            {--dry-run : Preview without sending}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Generate and send weekly performance report with analysis';

    /**
     * Execute the console command.
     */
    public function handle(
        EmailReportService $emailService,
        PerformanceHistoryService $historyService,
        PerformanceAlertService $alertService
    ) {
        $this->info('📊 Generating Weekly Performance Report...');
        $this->newLine();

        // Get recipients
        $recipients = $this->getRecipients();
        if (empty($recipients)) {
            $this->error('No recipients configured. Set PERFORMANCE_REPORT_EMAIL_* in .env');
            return 1;
        }

        // Calculate date ranges
        $period1End = now()->subWeek()->endOfWeek()->toDateString();
        $period1Start = now()->subWeek()->startOfWeek()->toDateString();
        $period2End = now()->subWeeks(2)->endOfWeek()->toDateString();
        $period2Start = now()->subWeeks(2)->startOfWeek()->toDateString();

        $this->info("📅 Period 1: {$period1Start} to {$period1End}");
        $this->info("📅 Period 2: {$period2Start} to {$period2End}");
        $this->newLine();

        // Generate comparison
        $this->info('🔄 Generating comparison data...');
        $comparison = $historyService->comparePeriods(
            $period1Start,
            $period1End,
            $period2Start,
            $period2End
        );

        // Display summary
        $this->displaySummary($comparison);

        // Get alert statistics
        $alertStats = $alertService->getStatistics();
        $this->displayAlertStats($alertStats);

        // Dry run mode
        if ($this->option('dry-run')) {
            $this->newLine();
            $this->warn('🔍 Dry run mode - no emails will be sent');
            $this->info('Recipients: ' . implode(', ', $recipients));
            return 0;
        }

        // Send reports
        $this->newLine();
        $this->info('📧 Sending reports...');

        $sent = 0;
        $failed = 0;

        foreach ($recipients as $recipient) {
            $this->line("  Sending to: {$recipient}...");
            
            $success = $emailService->sendReport(
                $recipient,
                $period1Start,
                $period1End,
                $period2Start,
                $period2End,
                [
                    'sender_name' => 'StudioBook Weekly Performance Report',
                    'attach_pdf' => true,
                ]
            );

            if ($success) {
                $this->info("    ✅ Sent successfully");
                $sent++;
            } else {
                $this->error("    ❌ Failed to send");
                $failed++;
            }
        }

        // Summary
        $this->newLine();
        $this->info('═══════════════════════════════════════════');
        $this->info('        Weekly Report Summary');
        $this->info('═══════════════════════════════════════════');
        $this->info("  Sent:   {$sent}");
        $this->info("  Failed: {$failed}");
        $this->info("  Total:  " . count($recipients));
        $this->info('═══════════════════════════════════════════');

        // Log
        Log::info('Weekly performance report sent', [
            'sent' => $sent,
            'failed' => $failed,
            'recipients' => $recipients,
        ]);

        return $failed > 0 ? 1 : 0;
    }

    /**
     * Get recipients list
     */
    protected function getRecipients(): array
    {
        $optionRecipients = $this->option('recipients');
        
        if ($optionRecipients) {
            return array_map('trim', explode(',', $optionRecipients));
        }

        return config('performance.email_recipients', [
            config('performance.alert_email', 'admin@studiobook.com'),
        ]);
    }

    /**
     * Display comparison summary
     */
    protected function displaySummary(array $comparison): void
    {
        $this->info('═══════════════════════════════════════════');
        $this->info('        Performance Comparison');
        $this->info('═══════════════════════════════════════════');

        foreach ($comparison['comparison'] as $metric => $data) {
            $change = $data['change']['percent'];
            $direction = $data['change']['direction'];
            $regression = $data['regression'] ? ' ⚠️' : '';
            
            $color = match(true) {
                $data['regression'] => 'error',
                $change < -5 => 'info',
                $change > 5 => 'comment',
                default => 'line',
            };

            $this->line(
                "  " . str_pad(ucfirst(str_replace('_', ' ', $metric)), 20) .
                " │ {$data['period1']['avg']}% → {$data['period2']['avg']}%" .
                " │ " . ($change > 0 ? '+' : '') . "{$change}%" .
                "{$regression}",
                $color
            );
        }

        $this->info('═══════════════════════════════════════════');

        // Regression summary
        if ($comparison['summary']['has_regressions']) {
            $this->newLine();
            $this->error("⚠️  {$comparison['summary']['regression_count']} regression(s) detected:");
            foreach ($comparison['summary']['regressions'] as $reg) {
                $this->error("    - {$reg['metric']}: +{$reg['change']}%");
            }
        } else {
            $this->newLine();
            $this->info('✅ No performance regressions detected');
        }

        if ($comparison['summary']['improvement_count'] > 0) {
            $this->info("📈 {$comparison['summary']['improvement_count']} metric(s) improved");
        }
    }

    /**
     * Display alert statistics
     */
    protected function displayAlertStats(array $stats): void
    {
        $this->newLine();
        $this->info('🔔 Alert Statistics (Last 7 days):');
        $this->line("   Total: {$stats['total']}");
        $this->line("   Active: {$stats['active']}");
        $this->line("   Critical: {$stats['critical']}");
        $this->line("   Warning: {$stats['warning']}");
    }
}
