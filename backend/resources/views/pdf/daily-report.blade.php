<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>{{ $title }} - {{ $date }}</title>
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
        .header h2 {
            color: #666;
            margin: 10px 0 5px;
            font-size: 16px;
            font-weight: normal;
        }
        .header p {
            color: #999;
            margin: 5px 0 0;
        }
        .summary-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 20px;
            margin-bottom: 30px;
        }
        .summary-card {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
        }
        .summary-card .value {
            font-size: 28px;
            font-weight: bold;
            color: #3B82F6;
        }
        .summary-card .label {
            font-size: 12px;
            color: #666;
            margin-top: 5px;
        }
        .section {
            margin-bottom: 30px;
        }
        .section h3 {
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
        .text-center {
            text-align: center;
        }
        .hourly-chart {
            display: flex;
            align-items: flex-end;
            height: 150px;
            padding: 20px 0;
            border-bottom: 1px solid #ddd;
        }
        .hourly-bar {
            flex: 1;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: flex-end;
        }
        .hourly-bar-fill {
            width: 30px;
            background: #3B82F6;
            border-radius: 4px 4px 0 0;
        }
        .hourly-bar-label {
            font-size: 10px;
            color: #666;
            margin-top: 5px;
        }
        .hourly-bar-value {
            font-size: 10px;
            font-weight: bold;
            margin-bottom: 5px;
        }
        .footer {
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #ddd;
            font-size: 10px;
            color: #999;
            text-align: center;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🎸 StudioBook</h1>
        <h2>{{ $title }}</h2>
        <p>{{ \Carbon\Carbon::parse($date)->format('l, d F Y') }}</p>
        <p>Pemilik: {{ $owner->name }}</p>
    </div>

    <div class="summary-grid">
        <div class="summary-card">
            <div class="value">{{ $summary['total_bookings'] }}</div>
            <div class="label">Total Booking</div>
        </div>
        <div class="summary-card">
            <div class="value">Rp {{ number_format($summary['revenue'], 0, ',', '.') }}</div>
            <div class="label">Total Pendapatan</div>
        </div>
        <div class="summary-card">
            <div class="value">{{ $summary['rooms_used'] }}</div>
            <div class="label">Ruangan Terpakai</div>
        </div>
    </div>

    @if($hourly_breakdown->count() > 0)
    <div class="section">
        <h3>Distribusi Jam</h3>
        <div class="hourly-chart">
            @php
                $maxCount = $hourly_breakdown->max('count');
            @endphp
            @foreach($hourly_breakdown as $hour)
            <div class="hourly-bar">
                <div class="hourly-bar-value">{{ $hour['count'] }}</div>
                <div class="hourly-bar-fill" style="height: {{ ($hour['count'] / $maxCount) * 100 }}px;"></div>
                <div class="hourly-bar-label">{{ $hour['hour'] }}</div>
            </div>
            @endforeach
        </div>
    </div>
    @endif

    <div class="section">
        <h3>Detail Booking</h3>
        <table>
            <thead>
                <tr>
                    <th>Kode</th>
                    <th>Waktu</th>
                    <th>Pelanggan</th>
                    <th>Studio</th>
                    <th>Ruangan</th>
                    <th class="text-right">Total</th>
                </tr>
            </thead>
            <tbody>
                @forelse($bookings as $booking)
                <tr>
                    <td><strong>{{ $booking->booking_code }}</strong></td>
                    <td>{{ $booking->start_time }} - {{ $booking->end_time }}</td>
                    <td>{{ $booking->user->name }}</td>
                    <td>{{ $booking->studio->name }}</td>
                    <td>{{ $booking->room->name }}</td>
                    <td class="text-right">Rp {{ number_format($booking->total_amount, 0, ',', '.') }}</td>
                </tr>
                @empty
                <tr>
                    <td colspan="6" class="text-center">Tidak ada booking hari ini</td>
                </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div class="footer">
        <p>Dicetak pada: {{ $generated_at }}</p>
        <p>StudioBook - Platform Booking Studio Musik</p>
    </div>
</body>
</html>
