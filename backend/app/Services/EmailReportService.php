<?php

namespace App\Services;

use App\Mail\PerformanceReportMail;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;

class EmailReportService
{
    protected PerformanceHistoryService $historyService;
    protected PdfService $pdfService;

    public function __construct(
        PerformanceHistoryService $historyService,
        PdfService $pdfService
    ) {
        $this->historyService = $historyService;
        $this->pdfService = $pdfService;
    }

    /**
     * Send performance report email
     */
    public function sendReport(
        string $recipient,
        string $period1Start,
        string $period1End,
        string $period2Start,
        string $period2End,
        array $options = []
    ): bool {
        try {
            // Generate comparison report
            $report = $this->historyService->exportReport(
                $period1Start,
                $period1End,
                $period2Start,
                $period2End,
                'json'
            );

            // Generate PDF attachment
            if ($options['attach_pdf'] ?? true) {
                $pdfPath = $this->pdfService->generatePerformanceReport($report);
                $report['pdf_path'] = $pdfPath;
            }

            // Send email
            Mail::to($recipient)->send(new PerformanceReportMail(
                $report,
                $options['sender_name'] ?? 'StudioBook Performance'
            ));

            // Log success
            Log::info('Performance report email sent', [
                'recipient' => $recipient,
                'period1' => "{$period1Start} to {$period1End}",
                'period2' => "{$period2Start} to {$period2End}",
            ]);

            return true;

        } catch (\Exception $e) {
            Log::error('Failed to send performance report email', [
                'recipient' => $recipient,
                'error' => $e->getMessage(),
            ]);

            return false;
        }
    }

    /**
     * Send weekly report to all admins
     */
    public function sendWeeklyReport(): array
    {
        $results = [
            'sent' => 0,
            'failed' => 0,
            'recipients' => [],
        ];

        // Get admin emails from config
        $recipients = config('performance.email_recipients', [
            config('performance.alert_email', 'admin@studiobook.com'),
        ]);

        // Calculate date ranges (last 7 days vs previous 7 days)
        $period1End = now()->subWeek()->toDateString();
        $period1Start = now()->subWeeks(2)->toDateString();
        $period2End = now()->subWeeks(2)->toDateString();
        $period2Start = now()->subWeeks(3)->toDateString();

        foreach ($recipients as $recipient) {
            $success = $this->sendReport(
                $recipient,
                $period1Start,
                $period1End,
                $period2Start,
                $period2End,
                ['sender_name' => 'StudioBook Weekly Report']
            );

            if ($success) {
                $results['sent']++;
            } else {
                $results['failed']++;
            }
            $results['recipients'][] = $recipient;
        }

        return $results;
    }

    /**
     * Send daily summary report
     */
    public function sendDailySummary(string $recipient): bool
    {
        // Get last 24 hours vs previous 24 hours
        $period1End = now()->toDateString();
        $period1Start = now()->subDay()->toDateString();
        $period2End = now()->subDay()->toDateString();
        $period2Start = now()->subDays(2)->toDateString();

        return $this->sendReport(
            $recipient,
            $period1Start,
            $period1End,
            $period2Start,
            $period2End,
            [
                'sender_name' => 'StudioBook Daily Summary',
                'attach_pdf' => false,
            ]
        );
    }

    /**
     * Send monthly report
     */
    public function sendMonthlyReport(string $recipient): bool
    {
        // Get last 30 days vs previous 30 days
        $period1End = now()->toDateString();
        $period1Start = now()->subDays(30)->toDateString();
        $period2End = now()->subDays(30)->toDateString();
        $period2Start = now()->subDays(60)->toDateString();

        return $this->sendReport(
            $recipient,
            $period1Start,
            $period1End,
            $period2Start,
            $period2End,
            [
                'sender_name' => 'StudioBook Monthly Report',
                'attach_pdf' => true,
            ]
        );
    }

    /**
     * Send regression alert email
     */
    public function sendRegressionAlert(
        string $recipient,
        array $regressions,
        array $currentMetrics
    ): bool {
        try {
            $subject = "⚠️ Performance Regression Alert - " . count($regressions) . " issues detected";

            $body = $this->buildRegressionEmailBody($regressions, $currentMetrics);

            Mail::raw($body, function ($message) use ($recipient, $subject) {
                $message->to($recipient)
                    ->subject($subject)
                    ->from(config('mail.from.address'), 'StudioBook Alerts');
            });

            Log::alert('Performance regression alert sent', [
                'recipient' => $recipient,
                'regressions' => array_column($regressions, 'metric'),
            ]);

            return true;

        } catch (\Exception $e) {
            Log::error('Failed to send regression alert', [
                'recipient' => $recipient,
                'error' => $e->getMessage(),
            ]);

            return false;
        }
    }

    /**
     * Build regression email body
     */
    protected function buildRegressionEmailBody(array $regressions, array $metrics): string
    {
        $html = "
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                .header { background: #dc2626; color: white; padding: 20px; text-align: center; }
                .content { padding: 20px; }
                .alert-box { background: #fef2f2; border: 1px solid #fecaca; padding: 15px; border-radius: 8px; margin: 15px 0; }
                .metric-item { padding: 10px; border-bottom: 1px solid #e5e7eb; }
                .metric-name { font-weight: bold; color: #1e293b; }
                .metric-change { color: #dc2626; font-weight: bold; }
                .footer { background: #f3f4f6; padding: 15px; text-align: center; font-size: 12px; color: #6b7280; }
            </style>
        </head>
        <body>
            <div class='header'>
                <h1>⚠️ Performance Regression Alert</h1>
            </div>
            <div class='content'>
                <p>The following performance regressions were detected:</p>
                <div class='alert-box'>";

        foreach ($regressions as $reg) {
            $html .= "
                    <div class='metric-item'>
                        <span class='metric-name'>{$reg['metric']}</span>
                        <span class='metric-change'>+{$reg['change']}%</span>
                    </div>";
        }

        $html .= "
                </div>
                <h3>Current Metrics:</h3>
                <ul>";

        foreach ($metrics as $key => $value) {
            $html .= "<li><strong>{$key}:</strong> {$value}</li>";
        }

        $html .= "
                </ul>
                <p>Please investigate and resolve these issues.</p>
            </div>
            <div class='footer'>
                <p>© " . date('Y') . " StudioBook Performance Monitoring</p>
            </div>
        </body>
        </html>";

        return $html;
    }

    /**
     * Get scheduled email report settings
     */
    public function getScheduleSettings(): array
    {
        return [
            'daily' => [
                'enabled' => config('performance.email_schedule.daily', false),
                'time' => config('performance.email_schedule.daily_time', '08:00'),
                'recipients' => config('performance.email_recipients', []),
            ],
            'weekly' => [
                'enabled' => config('performance.email_schedule.weekly', true),
                'day' => config('performance.email_schedule.weekly_day', 'monday'),
                'time' => config('performance.email_schedule.weekly_time', '09:00'),
                'recipients' => config('performance.email_recipients', []),
            ],
            'monthly' => [
                'enabled' => config('performance.email_schedule.monthly', true),
                'day' => config('performance.email_schedule.monthly_day', 1),
                'time' => config('performance.email_schedule.monthly_time', '09:00'),
                'recipients' => config('performance.email_recipients', []),
            ],
        ];
    }
}
