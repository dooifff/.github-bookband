<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Performance Report</title>
</head>
<body style="margin: 0; padding: 0; font-family: 'Helvetica Neue', Arial, sans-serif; background-color: #f4f7fa;">
    <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f4f7fa; padding: 20px;">
        <tr>
            <td align="center">
                <table width="600" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
                    <!-- Header -->
                    <tr>
                        <td style="background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%); padding: 30px; text-align: center;">
                            <h1 style="color: #ffffff; margin: 0; font-size: 24px;">🎸 StudioBook</h1>
                            <p style="color: rgba(255,255,255,0.9); margin: 10px 0 0 0; font-size: 14px;">Performance Report</p>
                        </td>
                    </tr>

                    <!-- Regressions Alert -->
                    @if($report['summary']['has_regressions'] ?? false)
                    <tr>
                        <td style="padding: 20px 30px 0 30px;">
                            <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #fef2f2; border: 1px solid #fecaca; border-radius: 8px;">
                                <tr>
                                    <td style="padding: 15px;">
                                        <p style="color: #dc2626; margin: 0; font-weight: bold;">⚠️ Performance Regressions Detected</p>
                                        <p style="color: #991b1b; margin: 5px 0 0 0; font-size: 13px;">
                                            @foreach($report['summary']['regressions'] ?? [] as $reg)
                                                {{ $reg['metric'] }} (+{{ number_format($reg['change'], 1) }}%){{ $loop->last ? '' : ', ' }}
                                            @endforeach
                                        </p>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                    @endif

                    <!-- Summary Cards -->
                    <tr>
                        <td style="padding: 25px 30px;">
                            <table width="100%" cellpadding="0" cellspacing="0">
                                <tr>
                                    <td width="25%" style="padding: 0 5px;">
                                        <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f8fafc; border-radius: 8px; text-align: center;">
                                            <tr>
                                                <td style="padding: 15px;">
                                                    <p style="color: #64748b; margin: 0; font-size: 11px; text-transform: uppercase;">Period 1</p>
                                                    <p style="color: #1e293b; margin: 5px 0 0 0; font-size: 20px; font-weight: bold;">{{ $report['periods']['period1']['stats']['count'] ?? 0 }}</p>
                                                    <p style="color: #94a3b8; margin: 5px 0 0 0; font-size: 10px;">Snapshots</p>
                                                </td>
                                            </tr>
                                        </table>
                                    </td>
                                    <td width="25%" style="padding: 0 5px;">
                                        <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f8fafc; border-radius: 8px; text-align: center;">
                                            <tr>
                                                <td style="padding: 15px;">
                                                    <p style="color: #64748b; margin: 0; font-size: 11px; text-transform: uppercase;">Period 2</p>
                                                    <p style="color: #1e293b; margin: 5px 0 0 0; font-size: 20px; font-weight: bold;">{{ $report['periods']['period2']['stats']['count'] ?? 0 }}</p>
                                                    <p style="color: #94a3b8; margin: 5px 0 0 0; font-size: 10px;">Snapshots</p>
                                                </td>
                                            </tr>
                                        </table>
                                    </td>
                                    <td width="25%" style="padding: 0 5px;">
                                        <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f8fafc; border-radius: 8px; text-align: center;">
                                            <tr>
                                                <td style="padding: 15px;">
                                                    <p style="color: #64748b; margin: 0; font-size: 11px; text-transform: uppercase;">Regressions</p>
                                                    <p style="color: {{ ($report['summary']['regression_count'] ?? 0) > 0 ? '#dc2626' : '#16a34a' }}; margin: 5px 0 0 0; font-size: 20px; font-weight: bold;">{{ $report['summary']['regression_count'] ?? 0 }}</p>
                                                </td>
                                            </tr>
                                        </table>
                                    </td>
                                    <td width="25%" style="padding: 0 5px;">
                                        <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f8fafc; border-radius: 8px; text-align: center;">
                                            <tr>
                                                <td style="padding: 15px;">
                                                    <p style="color: #64748b; margin: 0; font-size: 11px; text-transform: uppercase;">Improvements</p>
                                                    <p style="color: #16a34a; margin: 5px 0 0 0; font-size: 20px; font-weight: bold;">{{ $report['summary']['improvement_count'] ?? 0 }}</p>
                                                </td>
                                            </tr>
                                        </table>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>

                    <!-- Periods Info -->
                    <tr>
                        <td style="padding: 0 30px 20px 30px;">
                            <table width="100%" cellpadding="0" cellspacing="0">
                                <tr>
                                    <td width="50%" style="padding-right: 10px;">
                                        <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f8fafc; border-radius: 8px;">
                                            <tr>
                                                <td style="padding: 15px;">
                                                    <p style="color: #6366f1; margin: 0; font-weight: bold; font-size: 13px;">📅 Period 1 (Recent)</p>
                                                    <p style="color: #64748b; margin: 5px 0 0 0; font-size: 12px;">
                                                        {{ $report['periods']['period1']['start'] ?? 'N/A' }} to {{ $report['periods']['period1']['end'] ?? 'N/A' }}
                                                    </p>
                                                </td>
                                            </tr>
                                        </table>
                                    </td>
                                    <td width="50%" style="padding-left: 10px;">
                                        <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f8fafc; border-radius: 8px;">
                                            <tr>
                                                <td style="padding: 15px;">
                                                    <p style="color: #6366f1; margin: 0; font-weight: bold; font-size: 13px;">📅 Period 2 (Previous)</p>
                                                    <p style="color: #64748b; margin: 5px 0 0 0; font-size: 12px;">
                                                        {{ $report['periods']['period2']['start'] ?? 'N/A' }} to {{ $report['periods']['period2']['end'] ?? 'N/A' }}
                                                    </p>
                                                </td>
                                            </tr>
                                        </table>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>

                    <!-- Comparison Table -->
                    <tr>
                        <td style="padding: 0 30px 25px 30px;">
                            <h2 style="color: #1e293b; font-size: 16px; margin: 0 0 15px 0; border-bottom: 2px solid #e2e8f0; padding-bottom: 10px;">📊 Metric Comparison</h2>
                            <table width="100%" cellpadding="0" cellspacing="0" style="border-collapse: collapse;">
                                <thead>
                                    <tr style="background-color: #f1f5f9;">
                                        <th style="padding: 10px; text-align: left; font-size: 11px; color: #475569; border-bottom: 2px solid #e2e8f0;">Metric</th>
                                        <th style="padding: 10px; text-align: right; font-size: 11px; color: #475569; border-bottom: 2px solid #e2e8f0;">Period 1</th>
                                        <th style="padding: 10px; text-align: right; font-size: 11px; color: #475569; border-bottom: 2px solid #e2e8f0;">Period 2</th>
                                        <th style="padding: 10px; text-align: right; font-size: 11px; color: #475569; border-bottom: 2px solid #e2e8f0;">Change</th>
                                        <th style="padding: 10px; text-align: center; font-size: 11px; color: #475569; border-bottom: 2px solid #e2e8f0;">Status</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    @foreach($report['metrics'] ?? [] as $metric => $data)
                                    <tr style="border-bottom: 1px solid #e2e8f0;">
                                        <td style="padding: 10px; font-weight: 600; color: #1e293b; text-transform: capitalize;">{{ str_replace('_', ' ', $metric) }}</td>
                                        <td style="padding: 10px; text-align: right; color: #64748b;">{{ formatMetricValue($metric, $data['period1']['avg'] ?? 0) }}</td>
                                        <td style="padding: 10px; text-align: right; color: #64748b;">{{ formatMetricValue($metric, $data['period2']['avg'] ?? 0) }}</td>
                                        <td style="padding: 10px; text-align: right; color: {{ ($data['regression'] ?? false) ? '#dc2626' : (($data['change']['percent'] ?? 0) < 0 ? '#16a34a' : '#64748b') }}; font-weight: 600;">
                                            {{ ($data['change']['percent'] ?? 0) > 0 ? '+' : '' }}{{ number_format($data['change']['percent'] ?? 0, 1) }}%
                                        </td>
                                        <td style="padding: 10px; text-align: center;">
                                            @if($data['regression'] ?? false)
                                                <span style="background-color: #fef2f2; color: #dc2626; padding: 2px 8px; border-radius: 4px; font-size: 10px; font-weight: 600;">⚠️ Regression</span>
                                            @else
                                                <span style="background-color: #f0fdf4; color: #16a34a; padding: 2px 8px; border-radius: 4px; font-size: 10px; font-weight: 600;">✅ OK</span>
                                            @endif
                                        </td>
                                    </tr>
                                    @endforeach
                                </tbody>
                            </table>
                        </td>
                    </tr>

                    <!-- CTA Button -->
                    <tr>
                        <td style="padding: 0 30px 25px 30px; text-align: center;">
                            <table width="100%" cellpadding="0" cellspacing="0">
                                <tr>
                                    <td align="center">
                                        <a href="{{ config('app.url', 'http://localhost:8000') }}/comparison" style="display: inline-block; background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%); color: #ffffff; text-decoration: none; padding: 12px 30px; border-radius: 8px; font-weight: 600; font-size: 14px;">View Full Report →</a>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>

                    <!-- Footer -->
                    <tr>
                        <td style="background-color: #f8fafc; padding: 20px 30px; text-align: center; border-top: 1px solid #e2e8f0;">
                            <p style="color: #94a3b8; margin: 0; font-size: 11px;">
                                © {{ date('Y') }} StudioBook. Performance Monitoring Report.
                            </p>
                            <p style="color: #94a3b8; margin: 5px 0 0 0; font-size: 10px;">
                                This report was automatically generated by StudioBook Performance Monitoring System.
                            </p>
                            <p style="color: #94a3b8; margin: 10px 0 0 0; font-size: 10px;">
                                <a href="{{ config('app.url', 'http://localhost:8000') }}/settings" style="color: #6366f1; text-decoration: none;">Manage Email Preferences</a>
                            </p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
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
