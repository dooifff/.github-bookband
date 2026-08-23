<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>{{ $title }}</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            font-size: 11px;
            color: #333;
        }
        .header {
            text-align: center;
            margin-bottom: 20px;
            padding-bottom: 15px;
            border-bottom: 2px solid #3B82F6;
        }
        .header h1 {
            color: #3B82F6;
            margin: 0;
            font-size: 20px;
        }
        .header p {
            color: #666;
            margin: 5px 0 0;
            font-size: 11px;
        }
        .summary-row {
            display: flex;
            justify-content: space-around;
            margin-bottom: 20px;
            padding: 15px;
            background: #f8f9fa;
            border-radius: 8px;
        }
        .summary-item {
            text-align: center;
        }
        .summary-item .value {
            font-size: 20px;
            font-weight: bold;
            color: #3B82F6;
        }
        .summary-item .label {
            font-size: 10px;
            color: #666;
            margin-top: 5px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            font-size: 10px;
        }
        th, td {
            padding: 8px 6px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background: #3B82F6;
            color: white;
            font-weight: bold;
        }
        tr:nth-child(even) {
            background: #f9fafb;
        }
        .text-right {
            text-align: right;
        }
        .text-center {
            text-align: center;
        }
        .status-badge {
            display: inline-block;
            padding: 2px 8px;
            border-radius: 10px;
            font-size: 9px;
            font-weight: bold;
        }
        .status-pending {
            background: #fef3c7;
            color: #92400e;
        }
        .status-confirmed {
            background: #d1fae5;
            color: #065f46;
        }
        .status-completed {
            background: #dbeafe;
            color: #1e40af;
        }
        .status-cancelled {
            background: #fee2e2;
            color: #991b1b;
        }
        .footer {
            margin-top: 20px;
            padding-top: 15px;
            border-top: 1px solid #ddd;
            font-size: 9px;
            color: #999;
            text-align: center;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🎸 StudioBook - {{ $title }}</h1>
        <p>Pemilik: {{ $owner->name }}</p>
        <p>Periode: {{ \Carbon\Carbon::parse($period['start'])->format('d M Y') }} - {{ \Carbon\Carbon::parse($period['end'])->format('d M Y') }}</p>
    </div>

    <div class="summary-row">
        <div class="summary-item">
            <div class="value">{{ $summary['total_bookings'] }}</div>
            <div class="label">Total Booking</div>
        </div>
        <div class="summary-item">
            <div class="value" style="color: #10b981;">{{ $summary['confirmed'] }}</div>
            <div class="label">Dikonfirmasi</div>
        </div>
        <div class="summary-item">
            <div class="value" style="color: #3b82f6;">{{ $summary['completed'] }}</div>
            <div class="label">Selesai</div>
        </div>
        <div class="summary-item">
            <div class="value" style="color: #ef4444;">{{ $summary['cancelled'] }}</div>
            <div class="label">Dibatalkan</div>
        </div>
        <div class="summary-item">
            <div class="value" style="color: #10b981;">Rp {{ number_format($summary['total_revenue'], 0, ',', '.') }}</div>
            <div class="label">Total Pendapatan</div>
        </div>
    </div>

    <table>
        <thead>
            <tr>
                <th>Kode</th>
                <th>Tanggal</th>
                <th>Waktu</th>
                <th>Pelanggan</th>
                <th>Studio</th>
                <th>Ruangan</th>
                <th class="text-right">Total</th>
                <th class="text-center">Status</th>
            </tr>
        </thead>
        <tbody>
            @forelse($bookings as $booking)
            <tr>
                <td><strong>{{ $booking->booking_code }}</strong></td>
                <td>{{ \Carbon\Carbon::parse($booking->booking_date)->format('d/m/Y') }}</td>
                <td>{{ $booking->start_time }} - {{ $booking->end_time }}</td>
                <td>{{ $booking->user->name }}</td>
                <td>{{ $booking->studio->name }}</td>
                <td>{{ $booking->room->name }}</td>
                <td class="text-right">Rp {{ number_format($booking->total_amount, 0, ',', '.') }}</td>
                <td class="text-center">
                    @if($booking->status === 'pending')
                        <span class="status-badge status-pending">Pending</span>
                    @elseif($booking->status === 'confirmed')
                        <span class="status-badge status-confirmed">Confirmed</span>
                    @elseif($booking->status === 'completed')
                        <span class="status-badge status-completed">Selesai</span>
                    @elseif($booking->status === 'cancelled')
                        <span class="status-badge status-cancelled">Dibatalkan</span>
                    @else
                        <span class="status-badge">{{ $booking->status }}</span>
                    @endif
                </td>
            </tr>
            @empty
            <tr>
                <td colspan="8" class="text-center">Tidak ada data booking</td>
            </tr>
            @endforelse
        </tbody>
    </table>

    <div class="footer">
        <p>Dicetak pada: {{ $generated_at }}</p>
        <p>StudioBook - Platform Booking Studio Musik</p>
    </div>
</body>
</html>
