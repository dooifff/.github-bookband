<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Performance Report - StudioBook</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: 'Helvetica', 'Arial', sans-serif;
            font-size: 12px;
            line-height: 1.5;
            color: #333;
            background: #fff;
        }
        .container {
            padding: 20px;
        }
        .header {
            text-align: center;
            border-bottom: 3px solid #6366f1;
            padding-bottom: 20px;
            margin-bottom: 20px;
        }
        .header h1 {
            font-size: 24px;
            color: #6366f1;
            margin-bottom: 5px;
        }
        .header p {
            color: #666;
            font-size: 11px;
        }
        .logo {
            font-size: 28px;
            font-weight: bold;
            color: #6366f1;
            margin-bottom: 10px;
        }
        .summary-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 15px;
            margin-bottom: 25px;
        }
        .summary-card {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 15px;
            text-align: center;
        }
        .summary-card h3 {
            font-size: 11px;
            color: #64748b;
            text-transform: uppercase;
            margin-bottom: 5px;
        }
        .summary-card .value {
            font-size: 22px;
            font-weight: bold;
            color: #1e293b;
        }
        .summary-card .label {
            font-size: 10px;
            color: #94a3b8;
        }
        .section {
            margin-bottom: 25px;
        }
        .section-title {
            font-size: 16px;
            font-weight: bold;
            color: #1e293b;
            border-bottom: 2px solid #e2e8f0;
            padding-bottom: 8px;
            margin-bottom: 15px;
        }
        .comparison-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        .comparison-table th {
            background: #f1f5f9;
            padding: 10px;
            text-align: left;
            font-weight: 600;
            color: #475569;
            border-bottom: 2px solid #e2e8f0;
            font-size: 11px;
        }
        .comparison-table td {
            padding: 10px;
            border-bottom: 1px solid #e2e8f0;
        }
        .comparison-table tr:hover {
            background: #f8fafc;
        }
        .metric-name {
            font-weight: 600;
            color: #1e293b;
            text-transform: capitalize;
        }
        .value-good {
            color: #22c55e;
        }
        .value-warning {
            color: #f59e0b;
        }
        .value-critical {
            color: #ef4444;
        }
        .regression-badge {
            display: inline-block;
            padding: 2px 8px;
            background: #fef2f2;
            color: #dc2626;
            border-radius: 4px;
            font-size: 10px;
            font-weight: 600;
        }
        .ok-badge {
            display: inline-block;
            padding: 2px 8px;
            background: #f0fdf4;
            color: #16a34a;
            border-radius: 4px;
            font-size: 10px;
            font-weight: 600;
        }
        .periods-info {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin-bottom: 20px;
        }
        .period-box {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 15px;
        }
        .period-box h4 {
            color: #6366f1;
            margin-bottom: 10px;
            font-size: 13px;
        }
        .period-box p {
            color: #64748b;
            font-size: 11px;
        }
        .alert-box {
            padding: 12px;
            border-radius: 6px;
            margin-bottom: 15px;
        }
        .alert-danger {
            background: #fef2f2;
            border: 1px solid #fecaca;
            color: #dc2626;
        }
        .alert-success {
            background: #f0fdf4;
            border: 1px solid #bbf7d0;
            color: #16a34a;
        }
        .footer {
            margin-top: 30px;
            padding-top: 15px;
            border-top: 1px solid #e2e8f0;
            text-align: center;
            color: #94a3b8;
            font-size: 10px;
        }
        .page-break {
            page-break-before: always;
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- Header -->
        <div class="header">
            <div class="logo">🎸 StudioBook</div>
            <h1>Performance Comparison Report</h1>
            <p>Generated on {{ $report['generated_at'] }} | Powered by StudioBook Performance Monitoring</p>
        </div>

        <!-- Summary Cards -->
        <div class="summary-grid">
            <div class="summary-card">
                <h3>Period 1 Snapshots</h3>
                <div class="value">{{ $report['periods']['period1']['stats']['count'] ?? 0 }}</div>
                <div class="label">{{ $report['periods']['period1']['start'] }} to {{ $report['periods']['period1']['end'] }}</div>
            </div>
            <div class="summary-card">
                <h3>Period 2 Snapshots</h3>
                <div class="value">{{ $report['periods']['period2']['stats']['count'] ?? 0 }}</div>
                <div class="label">{{ $report['periods']['period2']['start'] }} to {{ $report['periods']['period2']['end'] }}</div>
            </div>
            <div class="summary-card">
                <h3>Regressions</h3>
                <div class="value" style="color: {{ $report['summary']['has_regressions'] ? '#ef4444' : '#22c55e' }}">
                    {{ $report['summary']['regression_count'] }}
                </div>
                <div class="label">Performance issues</div>
            </div>
            <div class="summary-card">
                <h3>Improvements</h3>
                <div class="value" style="color: #22c55e">{{ $report['summary']['improvement_count'] }}</div>
                <div class="label">Better performance</div>
            </div>
        </div>

        <!-- Alert Box -->
        @if($report['summary']['has_regressions'])
            <div class="alert-box alert-danger">
                <strong>⚠️ Performance Regressions Detected:</strong>
                @foreach($report['summary']['regressions'] as $reg)
                    {{ $reg['metric'] }} (+{{ number_format($reg['change'], 1) }}%){{ $loop->last ? '' : ', ' }}
                @endforeach
            </div>
        @else
            <div class="alert-box alert-success">
                <strong>✅ No Performance Regressions Detected</strong> - All metrics are within acceptable ranges.
            </div>
        @endif

        <!-- Comparison Table -->
        <div class="section">
            <h2 class="section-title">📊 Metric Comparison</h2>
            <table class="comparison-table">
                <thead>
                    <tr>
                        <th style="width: 25%">Metric</th>
                        <th style="width: 15%">Period 1 Avg</th>
                        <th style="width: 15%">Period 2 Avg</th>
                        <th style="width: 15%">Change</th>
                        <th style="width: 15%">Direction</th>
                        <th style="width: 15%">Status</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach($report['metrics'] as $metric => $data)
                        <tr>
                            <td class="metric-name">{{ str_replace('_', ' ', $metric) }}</td>
                            <td>{{ formatMetricValue($metric, $data['period1']['avg']) }}</td>
                            <td>{{ formatMetricValue($metric, $data['period2']['avg']) }}</td>
                            <td class="{{ $data['regression'] ? 'value-critical' : ($data['change']['percent'] < 0 ? 'value-good' : '') }}">
                                {{ $data['change']['percent'] > 0 ? '+' : '' }}{{ number_format($data['change']['percent'], 1) }}%
                            </td>
                            <td>{{ ucfirst($data['change']['direction']) }}</td>
                            <td>
                                @if($data['regression'])
                                    <span class="regression-badge">⚠️ Regression</span>
                                @else
                                    <span class="ok-badge">✅ OK</span>
                                @endif
                            </td>
                        </tr>
                    @endforeach
                </tbody>
            </table>
        </div>

        <!-- Detailed Metrics -->
        <div class="section">
            <h2 class="section-title">📈 Detailed Metric Analysis</h2>
            @foreach($report['metrics'] as $metric => $data)
                <div class="periods-info" style="margin-bottom: 10px;">
                    <div class="period-box">
                        <h4>{{ ucfirst(str_replace('_', ' ', $metric)) }} - Period 1</h4>
                        <p><strong>Average:</strong> {{ formatMetricValue($metric, $data['period1']['avg']) }}</p>
                        <p><strong>Min:</strong> {{ formatMetricValue($metric, $data['period1']['min']) }} | <strong>Max:</strong> {{ formatMetricValue($metric, $data['period1']['max']) }}</p>
                    </div>
                    <div class="period-box">
                        <h4>{{ ucfirst(str_replace('_', ' ', $metric)) }} - Period 2</h4>
                        <p><strong>Average:</strong> {{ formatMetricValue($metric, $data['period2']['avg']) }}</p>
                        <p><strong>Min:</strong> {{ formatMetricValue($metric, $data['period2']['min']) }} | <strong>Max:</strong> {{ formatMetricValue($metric, $data['period2']['max']) }}</p>
                    </div>
                </div>
            @endforeach
        </div>

        <!-- Footer -->
        <div class="footer">
            <p>© {{ date('Y') }} StudioBook. Performance Monitoring Report.</p>
            <p>This report was automatically generated by StudioBook Performance Monitoring System.</p>
        </div>
    </div>
</body>
</html>

<?php
function formatMetricValue($metric, $value) {
    if (strpos($metric, 'time') !== false || $metric === 'response_time') {
        return number_format($value, 1) . 'ms';
    }
    if (strpos($metric, 'rate') !== false || $metric === 'error_rate') {
        return number_format($value, 2) . '%';
    }
    if ($metric === 'requests_per_second') {
        return number_format($value, 0) . ' req/s';
    }
    return number_format($value, 1) . '%';
}
?>
