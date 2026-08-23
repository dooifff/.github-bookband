<?php

namespace App\Services;

use App\Models\Booking;
use App\Models\Payment;
use App\Models\Studio;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Barryvdh\DomPDF\Facade\Pdf;

class PdfExportService
{
    /**
     * Export revenue report as PDF
     */
    public function exportRevenueReport(int $ownerId, array $params = [])
    {
        $startDate = $params['start_date'] ?? Carbon::now()->startOfMonth()->toDateString();
        $endDate = $params['end_date'] ?? Carbon::now()->endOfMonth()->toDateString();

        // Get owner's studios
        $studioIds = Studio::where('owner_id', $ownerId)->pluck('id');

        // Get revenue data
        $revenue = Payment::whereHas('booking', function ($query) use ($studioIds) {
            $query->whereIn('studio_id', $studioIds);
        })
        ->where('status', 'completed')
        ->whereBetween('paid_at', [$startDate, $endDate])
        ->selectRaw('
            DATE(paid_at) as date,
            COUNT(*) as total_transactions,
            SUM(amount) as total_revenue,
            AVG(amount) as avg_transaction
        ')
        ->groupBy('date')
        ->orderBy('date')
        ->get();

        // Get summary
        $summary = [
            'total_revenue' => $revenue->sum('total_revenue'),
            'total_transactions' => $revenue->sum('total_transactions'),
            'avg_transaction' => $revenue->avg('avg_transaction'),
            'days' => $revenue->count(),
        ];

        // Get studio breakdown
        $studioBreakdown = Payment::whereHas('booking', function ($query) use ($studioIds) {
            $query->whereIn('studio_id', $studioIds);
        })
        ->where('status', 'completed')
        ->whereBetween('paid_at', [$startDate, $endDate])
        ->join('bookings', 'payments.booking_id', '=', 'bookings.id')
        ->join('studios', 'bookings.studio_id', '=', 'studios.id')
        ->selectRaw('
            studios.name as studio_name,
            COUNT(*) as total_transactions,
            SUM(payments.amount) as total_revenue
        ')
        ->groupBy('studios.id', 'studios.name')
        ->orderByDesc('total_revenue')
        ->get();

        // Get payment methods distribution
        $paymentMethods = Payment::whereHas('booking', function ($query) use ($studioIds) {
            $query->whereIn('studio_id', $studioIds);
        })
        ->where('status', 'completed')
        ->whereBetween('paid_at', [$startDate, $endDate])
        ->selectRaw('
            payment_method,
            COUNT(*) as count,
            SUM(amount) as total
        ')
        ->groupBy('payment_method')
        ->get();

        $data = [
            'title' => 'Laporan Pendapatan',
            'owner' => User::find($ownerId),
            'period' => [
                'start' => $startDate,
                'end' => $endDate,
            ],
            'summary' => $summary,
            'daily_data' => $revenue,
            'studio_breakdown' => $studioBreakdown,
            'payment_methods' => $paymentMethods,
            'generated_at' => Carbon::now()->toDateTimeString(),
        ];

        $pdf = Pdf::loadView('pdf.revenue-report', $data);
        $pdf->setPaper('a4', 'portrait');

        return $pdf;
    }

    /**
     * Export booking invoice as PDF
     */
    public function exportInvoice(int $bookingId)
    {
        $booking = Booking::with(['user', 'studio', 'room', 'payment'])
            ->findOrFail($bookingId);

        $data = [
            'title' => 'Invoice Booking',
            'booking' => $booking,
            'generated_at' => Carbon::now()->toDateTimeString(),
        ];

        $pdf = Pdf::loadView('pdf.invoice', $data);
        $pdf->setPaper('a4', 'portrait');

        return $pdf;
    }

    /**
     * Export booking summary as PDF
     */
    public function exportBookingSummary(int $ownerId, array $params = [])
    {
        $startDate = $params['start_date'] ?? Carbon::now()->startOfMonth()->toDateString();
        $endDate = $params['end_date'] ?? Carbon::now()->endOfMonth()->toDateString();
        $status = $params['status'] ?? null;

        $studioIds = Studio::where('owner_id', $ownerId)->pluck('id');

        $query = Booking::with(['user', 'studio', 'room'])
            ->whereIn('studio_id', $studioIds)
            ->whereBetween('date', [$startDate, $endDate]);

        if ($status) {
            $query->where('status', $status);
        }

        $bookings = $query->orderBy('date', 'desc')
            ->orderBy('start_time')
            ->get();

        // Summary stats
        $summary = [
            'total_bookings' => $bookings->count(),
            'confirmed' => $bookings->where('status', 'confirmed')->count(),
            'completed' => $bookings->where('status', 'completed')->count(),
            'cancelled' => $bookings->where('status', 'cancelled')->count(),
            'total_revenue' => $bookings->where('status', 'completed')->sum('total'),
        ];

        $data = [
            'title' => 'Ringkasan Booking',
            'owner' => User::find($ownerId),
            'period' => [
                'start' => $startDate,
                'end' => $endDate,
            ],
            'summary' => $summary,
            'bookings' => $bookings,
            'generated_at' => Carbon::now()->toDateTimeString(),
        ];

        $pdf = Pdf::loadView('pdf.booking-summary', $data);
        $pdf->setPaper('a4', 'landscape');

        return $pdf;
    }

    /**
     * Export daily report as PDF
     */
    public function exportDailyReport(int $ownerId, ?string $date = null)
    {
        $date = $date ?? Carbon::today()->toDateString();

        $studioIds = Studio::where('owner_id', $ownerId)->pluck('id');

        // Today's bookings
        $bookings = Booking::with(['user', 'studio', 'room'])
            ->whereIn('studio_id', $studioIds)
            ->where('date', $date)
            ->orderBy('start_time')
            ->get();

        // Today's revenue
        $revenue = Payment::whereHas('booking', function ($query) use ($studioIds) {
            $query->whereIn('studio_id', $studioIds);
        })
        ->where('status', 'completed')
        ->whereDate('paid_at', $date)
        ->sum('amount');

        // Hourly breakdown
        $hourlyBreakdown = $bookings->groupBy(function ($booking) {
            return Carbon::parse($booking->start_time)->format('H:00');
        })->map(function ($group, $hour) {
            return [
                'hour' => $hour,
                'count' => $group->count(),
                'revenue' => $group->sum('total'),
            ];
        })->values();

        $data = [
            'title' => 'Laporan Harian',
            'owner' => User::find($ownerId),
            'date' => $date,
            'summary' => [
                'total_bookings' => $bookings->count(),
                'revenue' => $revenue,
                'rooms_used' => $bookings->pluck('room_id')->unique()->count(),
            ],
            'bookings' => $bookings,
            'hourly_breakdown' => $hourlyBreakdown,
            'generated_at' => Carbon::now()->toDateTimeString(),
        ];

        $pdf = Pdf::loadView('pdf.daily-report', $data);
        $pdf->setPaper('a4', 'portrait');

        return $pdf;
    }
}
