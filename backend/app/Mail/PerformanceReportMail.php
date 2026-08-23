<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Attachment;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class PerformanceReportMail extends Mailable implements ShouldQueue
{
    use Queueable, SerializesModels;

    /**
     * The report data
     */
    protected array $report;

    /**
     * The sender name
     */
    protected string $senderName;

    /**
     * Create a new message instance
     */
    public function __construct(array $report, string $senderName = 'StudioBook Performance')
    {
        $this->report = $report;
        $this->senderName = $senderName;
    }

    /**
     * Get the message envelope
     */
    public function envelope(): Envelope
    {
        $period1 = $this->report['periods']['period1'] ?? [];
        $period2 = $this->report['periods']['period2'] ?? [];
        $hasRegressions = $this->report['summary']['has_regressions'] ?? false;

        $subject = $hasRegressions
            ? "⚠️ Performance Report - Regressions Detected"
            : "📊 Performance Report - " . date('Y-m-d');

        return new Envelope(
            subject: $subject,
            from: config('mail.from.address', 'noreply@studiobook.com'),
            tags: ['performance', 'report'],
        );
    }

    /**
     * Get the message content
     */
    public function content(): Content
    {
        return new Content(
            view: 'emails.performance-report',
            with: [
                'report' => $this->report,
                'senderName' => $this->senderName,
                'generatedAt' => $this->report['generated_at'] ?? now()->toISOString(),
            ]
        );
    }

    /**
     * Get the attachments
     */
    public function attachments(): array
    {
        $attachments = [];

        // Attach PDF if available
        if (isset($this->report['pdf_path']) && file_exists($this->report['pdf_path'])) {
            $attachments[] = Attachment::fromStorageDisk('local', $this->report['pdf_path'])
                ->as('performance-report-' . date('Y-m-d') . '.pdf')
                ->withMime('application/pdf');
        }

        // Attach CSV
        $csvContent = $this->generateCsv();
        if ($csvContent) {
            $attachments[] = Attachment::fromContent($csvContent)
                ->as('performance-report-' . date('Y-m-d') . '.csv')
                ->withMime('text/csv');
        }

        return $attachments;
    }

    /**
     * Generate CSV content for attachment
     */
    protected function generateCsv(): string
    {
        $output = fopen('php://temp', 'r+');

        // Header
        fputcsv($output, [
            'Metric',
            'Period 1 Avg',
            'Period 1 Min',
            'Period 1 Max',
            'Period 2 Avg',
            'Period 2 Min',
            'Period 2 Max',
            'Change %',
            'Direction',
            'Regression'
        ]);

        // Data rows
        foreach ($this->report['metrics'] ?? [] as $metric => $data) {
            fputcsv($output, [
                $metric,
                $data['period1']['avg'] ?? 0,
                $data['period1']['min'] ?? 0,
                $data['period1']['max'] ?? 0,
                $data['period2']['avg'] ?? 0,
                $data['period2']['min'] ?? 0,
                $data['period2']['max'] ?? 0,
                $data['change']['percent'] ?? 0,
                $data['change']['direction'] ?? 'unknown',
                $data['regression'] ? 'Yes' : 'No',
            ]);
        }

        rewind($output);
        $csv = stream_get_contents($output);
        fclose($output);

        return $csv;
    }

    /**
     * Get the report data
     */
    public function getReport(): array
    {
        return $this->report;
    }
}
