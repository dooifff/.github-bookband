<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Services\PerformanceHistoryService;
use Barryvdh\DomPDF\Facade\Pdf;

class PerformanceComparisonController extends Controller
{
    protected PerformanceHistoryService $historyService;

    public function __construct(PerformanceHistoryService $historyService)
    {
        $this->historyService = $historyService;
    }

    /**
     * Get performance history
     */
    public function history(Request $request)
    {
        $hours = $request->get('hours', 24);
        $metric = $request->get('metric');
        $limit = $request->get('limit', 100);

        $history = $this->historyService->getHistory($hours, $metric, $limit);

        return response()->json([
            'success' => true,
            'data' => $history,
            'meta' => [
                'hours' => $hours,
                'metric' => $metric,
                'count' => count($history),
            ],
        ]);
    }

    /**
     * Compare two time periods
     */
    public function compare(Request $request)
    {
        $request->validate([
            'period1_start' => 'required|date',
            'period1_end' => 'required|date|after:period1_start',
            'period2_start' => 'required|date',
            'period2_end' => 'required|date|after:period2_start',
        ]);

        $comparison = $this->historyService->comparePeriods(
            $request->input('period1_start'),
            $request->input('period1_end'),
            $request->input('period2_start'),
            $request->input('period2_end')
        );

        return response()->json([
            'success' => true,
            'data' => $comparison,
        ]);
    }

    /**
     * Get performance trend for a metric
     */
    public function trend(Request $request, string $metric)
    {
        $days = $request->get('days', 7);

        $trend = $this->historyService->getTrend($metric, $days);

        return response()->json([
            'success' => true,
            'data' => [
                'metric' => $metric,
                'days' => $days,
                'trend' => $trend,
            ],
        ]);
    }

    /**
     * Get daily summaries
     */
    public function dailySummaries(Request $request)
    {
        $request->validate([
            'start_date' => 'required|date',
            'end_date' => 'required|date|after:start_date',
        ]);

        $summaries = $this->historyService->getDailySummaries(
            $request->input('start_date'),
            $request->input('end_date')
        );

        return response()->json([
            'success' => true,
            'data' => $summaries,
            'meta' => [
                'start_date' => $request->input('start_date'),
                'end_date' => $request->input('end_date'),
                'count' => count($summaries),
            ],
        ]);
    }

    /**
     * Export comparison report
     */
    public function export(Request $request)
    {
        $request->validate([
            'period1_start' => 'required|date',
            'period1_end' => 'required|date|after:period1_start',
            'period2_start' => 'required|date',
            'period2_end' => 'required|date|after:period2_start',
            'format' => 'in:json,markdown,csv,pdf',
        ]);

        $report = $this->historyService->exportReport(
            $request->input('period1_start'),
            $request->input('period1_end'),
            $request->input('period2_start'),
            $request->input('period2_end'),
            $request->input('format', 'json')
        );

        $format = $request->input('format', 'json');

        switch ($format) {
            case 'markdown':
                return response()->markdown(
                    $this->generateMarkdownReport($report),
                    200,
                    ['Content-Disposition' => 'attachment; filename="performance-report.md"']
                );

            case 'csv':
                return response()->csv(
                    $this->generateCsvReport($report),
                    200,
                    ['Content-Disposition' => 'attachment; filename="performance-report.csv"']
                );

            case 'pdf':
                return $this->generatePdfReport($report);

            default:
                return response()->json([
                    'success' => true,
                    'data' => $report,
                ]);
        }
    }

    /**
     * Generate PDF report
     */
    protected function generatePdfReport(array $report)
    {
        $pdf = Pdf::loadView('reports.performance', ['report' => $report])
            ->setPaper('a4', 'portrait')
            ->setOption('tempDir', storage_path('app/cache/dompdf'))
            ->setOption('isHtml5ParserEnabled', true)
            ->setOption('isRemoteEnabled', false)
            ->setOption('isPhpEnabled', true);

        $filename = 'performance-report-' . now()->format('Y-m-d-His') . '.pdf';

        return $pdf->download($filename);
    }

    /**
     * Store a performance snapshot
     */
    public function storeSnapshot(Request $request)
    {
        $request->validate([
            'metrics' => 'required|array',
        ]);

        $snapshot = $this->historyService->storeSnapshot($request->input('metrics'));

        return response()->json([
            'success' => true,
            'data' => $snapshot,
        ], 201);
    }

    /**
     * Generate markdown report
     */
    protected function generateMarkdownReport(array $report): string
    {
        $md = "# Performance Comparison Report\n\n";
        $md .= "**Generated:** {$report['generated_at']}\n\n";
        $md .= "## Time Periods\n\n";
        $md .= "- **Period 1:** {$report['periods']['period1']['start']} to {$report['periods']['period1']['end']}\n";
        $md .= "- **Period 2:** {$report['periods']['period2']['start']} to {$report['periods']['period2']['end']}\n\n";

        $md .= "## Comparison Results\n\n";
        $md .= "| Metric | Period 1 Avg | Period 2 Avg | Change | Status |\n";
        $md .= "|--------|--------------|--------------|--------|--------|\n";

        foreach ($report['metrics'] as $metric => $data) {
            $p1Avg = $data['period1']['avg'];
            $p2Avg = $data['period2']['avg'];
            $change = $data['change']['percent'];
            $status = $data['regression'] ? '⚠️ Regression' : '✅ OK';

            $md .= "| {$metric} | {$p1Avg} | {$p2Avg} | {$change}% | {$status} |\n";
        }

        $md .= "\n## Summary\n\n";
        $md .= "- **Regressions:** {$report['summary']['regression_count']}\n";
        $md .= "- **Improvements:** {$report['summary']['improvement_count']}\n";

        if (!empty($report['summary']['regressions'])) {
            $md .= "\n### Regressions\n\n";
            foreach ($report['summary']['regressions'] as $reg) {
                $md .= "- {$reg['metric']}: +{$reg['change']}%\n";
            }
        }

        return $md;
    }

    /**
     * Generate CSV report
     */
    protected function generateCsvReport(array $report): array
    {
        $csv = [['Metric', 'Period 1 Avg', 'Period 1 Min', 'Period 1 Max', 'Period 2 Avg', 'Period 2 Min', 'Period 2 Max', 'Change %', 'Regression']];

        foreach ($report['metrics'] as $metric => $data) {
            $csv[] = [
                $metric,
                $data['period1']['avg'],
                $data['period1']['min'],
                $data['period1']['max'],
                $data['period2']['avg'],
                $data['period2']['min'],
                $data['period2']['max'],
                $data['change']['percent'],
                $data['regression'] ? 'Yes' : 'No',
            ];
        }

        return $csv;
    }
}
