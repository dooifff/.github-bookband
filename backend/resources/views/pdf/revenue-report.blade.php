<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>{{ $title }}</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            font-size: 12px;
            color: #333;
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 2px solid #3B82F6;
        }
        .header h1 {
            color: #3B82F6;
            margin: 0;
            font-size: 24px;
        }
        .header p {
            color: #666;
            margin: 5px 0 0;
        }
        .summary-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 20px;
            margin-bottom: 30px;
        }
        .summary-card {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 8px;
            border-left: 4px solid #3B82F6;
        }
        .summary-card h3 {
            margin: 0 0 10px;
            font-size: 14px;
            color: #666;
        }
        .summary-card .value {
            font-size: 24px;
            font-weight: bold;
            color: #333;
        }
        .section {
            margin-bottom: 30px;
        }
        .section h2 {
            font-size: 16px;
            color: #3B82F6;
            border-bottom: 1px solid #ddd;
            padding-bottom: 10px;
            margin-bottom: 15px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
        }
        th, td {
            padding: 10px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background: #f8f9fa;
            font-weight: bold;
            color: #666;
        }
        .text-right {
            text-align: right;
        }
        .footer {
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #ddd;
            font-size: 10px;
            color: #999;
            text-align: center;
        }
        .studio-bar {
            display: flex;
            align-items: center;
            margin-bottom: 8px;
        }
        .studio-name {
            width: 150px;
            font-weight: bold;
        }
        .studio-bar-fill {
            flex: 1;
            height: 20px;
            background: #e0e7ff;
            border-radius: 4px;
            overflow: hidden;
        }
        .studio-bar-inner {
            height: 100%;
            background: #3B82F6;
        }
        .studio-revenue {
            width: 120px;
            text-align: right;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🎸 StudioBook</h1>
        <h2>{{ $title }}</h2>
        <p>Periode: {{ \Carbon\Carbon::parse($period['start'])->format('d M Y') }} - {{ \Carbon\Carbon::parse($period['end'])->format('d M Y') }}</p>
        <p>Pemilik: {{ $owner->name }}</p>
    </div>

    <div class="summary-grid">
        <div class="summary-card">
            <h3>Total Pendapatan</h3>
            <div class="value">Rp {{ number_format($summary['total_revenue'], 0, ',', '.') }}</div>
        </div>
        <div class="summary-card">
            <h3>Total Transaksi</h3>
            <div class="value">{{ $summary['total_transactions'] }}</div>
        </div>
        <div class="summary-card">
            <h3>Rata-rata per Transaksi</h3>
            <div class="value">Rp {{ number_format($summary['avg_transaction'], 0, ',', '.') }}</div>
        </div>
        <div class="summary-card">
            <h3>Hari Aktif</h3>
            <div class="value">{{ $summary['days'] }} hari</div>
        </div>
    </div>

    @if($studio_breakdown->count() > 0)
    <div class="section">
        <h2>Pendapatan per Studio</h2>
        @php
            $maxRevenue = $studio_breakdown->max('total_revenue');
        @endphp
        @foreach($studio_breakdown as $studio)
        <div class="studio-bar">
            <div class="studio-name">{{ $studio->studio_name }}</div>
            <div class="studio-bar-fill">
                <div class="studio-bar-inner" style="width: {{ ($studio->total_revenue / $maxRevenue) * 100 }}%"></div>
            </div>
            <div class="studio-revenue">Rp {{ number_format($studio->total_revenue, 0, ',', '.') }}</div>
        </div>
        @endforeach
    </div>
    @endif

    @if($payment_methods->count() > 0)
    <div class="section">
        <h2>Metode Pembayaran</h2>
        <table>
            <thead>
                <tr>
                    <th>Metode</th>
                    <th class="text-right">Jumlah</th>
                    <th class="text-right">Total</th>
                </tr>
            </thead>
            <tbody>
                @foreach($payment_methods as $method)
                <tr>
                    <td>{{ ucfirst(str_replace('_', ' ', $method->payment_method)) }}</td>
                    <td class="text-right">{{ $method->count }}</td>
                    <td class="text-right">Rp {{ number_format($method->total, 0, ',', '.') }}</td>
                </tr>
                @endforeach
            </tbody>
        </table>
    </div>
    @endif

    @if($daily_data->count() > 0)
    <div class="section">
        <h2>Pendapatan Harian</h2>
        <table>
            <thead>
                <tr>
                    <th>Tanggal</th>
                    <th class="text-right">Transaksi</th>
                    <th class="text-right">Total</th>
                    <th class="text-right">Rata-rata</th>
                </tr>
            </thead>
            <tbody>
                @foreach($daily_data as $day)
                <tr>
                    <td>{{ \Carbon\Carbon::parse($day->date)->format('d M Y') }}</td>
                    <td class="text-right">{{ $day->total_transactions }}</td>
                    <td class="text-right">Rp {{ number_format($day->total_revenue, 0, ',', '.') }}</td>
                    <td class="text-right">Rp {{ number_format($day->avg_transaction, 0, ',', '.') }}</td>
                </tr>
                @endforeach
            </tbody>
        </table>
    </div>
    @endif

    <div class="footer">
        <p>Dicetak pada: {{ $generated_at }}</p>
        <p>StudioBook - Platform Booking Studio Musik</p>
    </div>
</body>
</html>
