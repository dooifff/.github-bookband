<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Invoice {{ $booking->booking_code }}</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            font-size: 12px;
            color: #333;
            line-height: 1.6;
        }
        .header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 2px solid #3B82F6;
        }
        .logo {
            font-size: 24px;
            font-weight: bold;
            color: #3B82F6;
        }
        .invoice-info {
            text-align: right;
        }
        .invoice-info h1 {
            margin: 0;
            font-size: 28px;
            color: #3B82F6;
        }
        .invoice-info p {
            margin: 5px 0;
            color: #666;
        }
        .content {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 30px;
            margin-bottom: 30px;
        }
        .section h3 {
            font-size: 14px;
            color: #3B82F6;
            margin: 0 0 15px;
            padding-bottom: 10px;
            border-bottom: 1px solid #ddd;
        }
        .info-row {
            display: flex;
            margin-bottom: 8px;
        }
        .info-label {
            width: 120px;
            color: #666;
        }
        .info-value {
            font-weight: bold;
        }
        .booking-details {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 30px;
        }
        .booking-details h3 {
            margin: 0 0 15px;
            font-size: 14px;
            color: #3B82F6;
        }
        .details-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 15px;
        }
        .detail-item {
            text-align: center;
        }
        .detail-item .label {
            font-size: 11px;
            color: #666;
            margin-bottom: 5px;
        }
        .detail-item .value {
            font-size: 16px;
            font-weight: bold;
            color: #333;
        }
        .pricing {
            margin-top: 30px;
        }
        .pricing table {
            width: 100%;
            border-collapse: collapse;
        }
        .pricing th, .pricing td {
            padding: 12px;
            text-align: right;
            border-bottom: 1px solid #ddd;
        }
        .pricing th {
            background: #f8f9fa;
            text-align: left;
        }
        .pricing .total-row {
            background: #3B82F6;
            color: white;
            font-weight: bold;
        }
        .pricing .total-row td {
            border-bottom: none;
        }
        .status-badge {
            display: inline-block;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: bold;
            text-transform: uppercase;
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
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #ddd;
            font-size: 10px;
            color: #999;
        }
        .footer p {
            margin: 5px 0;
        }
        .terms {
            margin-top: 30px;
            padding: 15px;
            background: #fffbeb;
            border: 1px solid #fbbf24;
            border-radius: 8px;
        }
        .terms h4 {
            margin: 0 0 10px;
            color: #92400e;
        }
        .terms ul {
            margin: 0;
            padding-left: 20px;
        }
        .terms li {
            margin-bottom: 5px;
            color: #78350f;
        }
    </style>
</head>
<body>
    <div class="header">
        <div>
            <div class="logo">🎸 StudioBook</div>
            <p>Platform Booking Studio Musik</p>
        </div>
        <div class="invoice-info">
            <h1>INVOICE</h1>
            <p><strong>{{ $booking->booking_code }}</strong></p>
            <p>Tanggal: {{ $booking->created_at->format('d M Y') }}</p>
        </div>
    </div>

    <div class="content">
        <div class="section">
            <h3>Informasi Pelanggan</h3>
            <div class="info-row">
                <div class="info-label">Nama</div>
                <div class="info-value">{{ $booking->user->name }}</div>
            </div>
            <div class="info-row">
                <div class="info-label">Email</div>
                <div class="info-value">{{ $booking->user->email }}</div>
            </div>
            @if($booking->user->phone)
            <div class="info-row">
                <div class="info-label">Telepon</div>
                <div class="info-value">{{ $booking->user->phone }}</div>
            </div>
            @endif
        </div>
        <div class="section">
            <h3>Informasi Studio</h3>
            <div class="info-row">
                <div class="info-label">Studio</div>
                <div class="info-value">{{ $booking->studio->name }}</div>
            </div>
            <div class="info-row">
                <div class="info-label">Ruangan</div>
                <div class="info-value">{{ $booking->room->name }}</div>
            </div>
            <div class="info-row">
                <div class="info-label">Lokasi</div>
                <div class="info-value">{{ $booking->studio->city }}</div>
            </div>
        </div>
    </div>

    <div class="booking-details">
        <h3>Detail Booking</h3>
        <div class="details-grid">
            <div class="detail-item">
                <div class="label">Tanggal</div>
                <div class="value">{{ \Carbon\Carbon::parse($booking->booking_date)->format('d M Y') }}</div>
            </div>
            <div class="detail-item">
                <div class="label">Waktu</div>
                <div class="value">{{ $booking->start_time }} - {{ $booking->end_time }}</div>
            </div>
            <div class="detail-item">
                <div class="label">Durasi</div>
                <div class="value">{{ \Carbon\Carbon::parse($booking->start_time)->diffInHours(\Carbon\Carbon::parse($booking->end_time)) }} Jam</div>
            </div>
        </div>
    </div>

    <div class="pricing">
        <table>
            <thead>
                <tr>
                    <th>Deskripsi</th>
                    <th class="text-right">Harga</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td>Sewa {{ $booking->room->name }} ({{ \Carbon\Carbon::parse($booking->start_time)->diffInHours(\Carbon\Carbon::parse($booking->end_time)) }} jam)</td>
                    <td class="text-right">Rp {{ number_format($booking->room->price_per_hour * \Carbon\Carbon::parse($booking->start_time)->diffInHours(\Carbon\Carbon::parse($booking->end_time)), 0, ',', '.') }}</td>
                </tr>
                @if($booking->discount_amount && $booking->discount_amount > 0)
                <tr>
                    <td>Discount @if($booking->promo_code) ({{ $booking->promo_code }}) @endif</td>
                    <td class="text-right" style="color: #10b981;">- Rp {{ number_format($booking->discount_amount, 0, ',', '.') }}</td>
                </tr>
                @endif
                <tr class="total-row">
                    <td><strong>TOTAL</strong></td>
                    <td class="text-right"><strong>Rp {{ number_format($booking->total_amount, 0, ',', '.') }}</strong></td>
                </tr>
            </tbody>
        </table>
    </div>

    <div style="text-align: center; margin: 30px 0;">
        <p>Status Pembayaran:</p>
        @if($booking->status === 'confirmed')
            <span class="status-badge status-confirmed">✓ Dikonfirmasi</span>
        @elseif($booking->status === 'completed')
            <span class="status-badge status-completed">✓ Selesai</span>
        @elseif($booking->status === 'cancelled')
            <span class="status-badge status-cancelled">✕ Dibatalkan</span>
        @else
            <span class="status-badge">{{ strtoupper($booking->status) }}</span>
        @endif
    </div>

    <div class="terms">
        <h4>Syarat & Ketentuan</h4>
        <ul>
            <li>Pembatalan yang dilakukan kurang dari 24 jam sebelum waktu booking tidak akan mendapatkan refund</li>
            <li>Pembatalan yang dilakukan lebih dari 24 jam sebelum waktu booking akan mendapatkan refund 50%</li>
            <li>Pelanggan wajib datang tepat waktu sesuai jadwal yang telah dipesan</li>
            <li>Keterlambatan pelanggan tidak akan memperpanjang waktu booking</li>
        </ul>
    </div>

    <div class="footer">
        <p><strong>StudioBook</strong> - Platform Booking Studio Musik</p>
        <p>Email: support@studiobook.com | Telp: +62 21 1234 5678</p>
        <p>Invoice ini merupakan bukti pembayaran yang sah</p>
        <p>Dicetak pada: {{ $generated_at }}</p>
    </div>
</body>
</html>
