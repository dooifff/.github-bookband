<?php

namespace App\Services;

use Barryvdh\DomPDF\PDF;
use Illuminate\Support\Facades\Storage;

class PdfService
{
    protected PDF $pdf;

    public function __construct(PDF $pdf)
    {
        $this->pdf = $pdf;
    }

    /**
     * Generate performance report PDF
     */
    public function generatePerformanceReport(array $report): string
    {
        $this->pdf->loadView('reports.performance', ['report' => $report])
            ->setPaper('a4', 'portrait')
            ->setOption('tempDir', storage_path('app/cache/dompdf'))
            ->setOption('isHtml5ParserEnabled', true)
            ->setOption('isRemoteEnabled', false)
            ->setOption('isPhpEnabled', true);

        $filename = 'performance-report-' . now()->format('Y-m-d-His') . '.pdf';
        $path = storage_path('app/reports/' . $filename);

        // Ensure directory exists
        if (!is_dir(storage_path('app/reports'))) {
            mkdir(storage_path('app/reports'), 0755, true);
        }

        $this->pdf->save($path);

        return $path;
    }

    /**
     * Download performance report PDF
     */
    public function downloadPerformanceReport(array $report)
    {
        $this->pdf->loadView('reports.performance', ['report' => $report])
            ->setPaper('a4', 'portrait')
            ->setOption('tempDir', storage_path('app/cache/dompdf'))
            ->setOption('isHtml5ParserEnabled', true)
            ->setOption('isRemoteEnabled', false)
            ->setOption('isPhpEnabled', true);

        $filename = 'performance-report-' . now()->format('Y-m-d-His') . '.pdf';

        return $this->pdf->download($filename);
    }

    /**
     * Stream performance report PDF
     */
    public function streamPerformanceReport(array $report, string $filename = 'performance-report.pdf')
    {
        $this->pdf->loadView('reports.performance', ['report' => $report])
            ->setPaper('a4', 'portrait')
            ->setOption('tempDir', storage_path('app/cache/dompdf'))
            ->setOption('isHtml5ParserEnabled', true)
            ->setOption('isRemoteEnabled', false)
            ->setOption('isPhpEnabled', true);

        return $this->pdf->stream($filename);
    }

    /**
     * Generate custom PDF from view
     */
    public function generateFromView(string $view, array $data, array $options = []): string
    {
        $this->pdf->loadView($view, $data);

        if (isset($options['paper'])) {
            $this->pdf->setPaper($options['paper']['size'] ?? 'a4', $options['paper']['orientation'] ?? 'portrait');
        }

        $this->pdf->setOption('tempDir', storage_path('app/cache/dompdf'));

        foreach ($options['options'] ?? [] as $key => $value) {
            $this->pdf->setOption($key, $value);
        }

        $filename = $options['filename'] ?? 'document-' . now()->format('Y-m-d-His') . '.pdf';
        $path = storage_path('app/reports/' . $filename);

        if (!is_dir(storage_path('app/reports'))) {
            mkdir(storage_path('app/reports'), 0755, true);
        }

        $this->pdf->save($path);

        return $path;
    }

    /**
     * Get PDF content as string
     */
    public function getContent(string $view, array $data, array $options = []): string
    {
        $this->pdf->loadView($view, $data)
            ->setPaper($options['paper'] ?? 'a4', $options['orientation'] ?? 'portrait')
            ->setOption('tempDir', storage_path('app/cache/dompdf'));

        return $this->pdf->output();
    }

    /**
     * Clean up old reports
     */
    public function cleanOldReports(int $days = 30): int
    {
        $path = storage_path('app/reports');
        if (!is_dir($path)) {
            return 0;
        }

        $count = 0;
        $files = glob($path . '/*.pdf');
        $cutoff = now()->subDays($days);

        foreach ($files as $file) {
            if (filemtime($file) < $cutoff->getTimestamp()) {
                unlink($file);
                $count++;
            }
        }

        return $count;
    }
}
