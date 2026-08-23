<?php

namespace App\Http\Controllers;

use App\Models\Payment;
use App\Models\Booking;
use App\Models\Studio;
use App\Services\PdfExportService;
use App\Services\ExcelExportService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Response;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class OwnerRevenueController extends Controller
{
    /**
     * Get revenue summary
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $studioIds = $user->ownedStudios()->pluck('id');

        // Total revenue
        $totalRevenue = Payment::whereHas('booking', function ($query) use ($studioIds) {
            $query->whereIn('studio_id', $studioIds);
        })
        ->where('status', 'paid')
        ->sum('amount');

        // This month revenue
        $thisMonthRevenue = Payment::whereHas('booking', function ($query) use ($studioIds) {
            $query->whereIn('studio_id', $studioIds);
        })
        ->where('status', 'paid')
        ->whereBetween('paid_at', [now()->startOfMonth(), now()])
        ->sum('amount');

        // Last month revenue
        $lastMonthRevenue = Payment::whereHas('booking', function ($query) use ($studioIds) {
            $query->whereIn('studio_id', $studioIds);
        })
        ->where('status', 'paid')
        ->whereBetween('paid_at', [now()->subMonth()->startOfMonth(), now()->subMonth()->endOfMonth()])
        ->sum('amount');

        // This year revenue
        $thisYearRevenue = Payment::whereHas('booking', function ($query) use ($studioIds) {
            $query->whereIn('studio_id', $studioIds);
        })
        ->where('status', 'paid')
        ->whereBetween('paid_at', [now()->startOfYear(), now()])
        ->sum('amount');

        // Pending payments (awaiting payment)
        $pendingPayments = Payment::whereHas('booking', function ($query) use ($studioIds) {
            $query->whereIn('studio_id', $studioIds);
        })
        ->where('status', 'pending')
        ->sum('amount');

        // Refunded amount
        $refundedAmount = Payment::whereHas('booking', function ($query) use ($studioIds) {
            $query->whereIn('studio_id', $studioIds);
        })
        ->where('status', 'refunded')
        ->sum('amount');

        // Revenue by studio - use DB aggregation to avoid N+1
        $revenueByStudio = Payment::whereHas('booking', function ($query) use ($studioIds) {
            $query->whereIn('studio_id', $studioIds);
        })
        ->where('payments.status', 'paid')
        ->join('bookings', 'payments.booking_id', '=', 'bookings.id')
        ->join('studios', 'bookings.studio_id', '=', 'studios.id')
        ->selectRaw('bookings.studio_id, studios.name as studio_name, SUM(payments.amount) as total_revenue, COUNT(*) as transaction_count')
        ->groupBy('bookings.studio_id', 'studios.name')
        ->get();

        // Monthly revenue for the last 12 months
        $monthlyRevenue = Payment::whereHas('booking', function ($query) use ($studioIds) {
            $query->whereIn('studio_id', $studioIds);
        })
        ->where('payments.status', 'paid')
        ->where('paid_at', '>=', now()->subMonths(12))
        ->selectRaw("strftime('%Y', paid_at) as year, strftime('%m', paid_at) as month, SUM(amount) as revenue")
        ->groupBy('year', 'month')
        ->orderBy('year')
        ->orderBy('month')
        ->get();

        return response()->json([
            'success' => true,
            'data' => [
                'summary' => [
                    'total_revenue' => $totalRevenue,
                    'this_month' => $thisMonthRevenue,
                    'last_month' => $lastMonthRevenue,
                    'this_year' => $thisYearRevenue,
                    'pending_payments' => $pendingPayments,
                    'refunded' => $refundedAmount,
                ],
                'revenue_by_studio' => $revenueByStudio,
                'monthly_revenue' => $monthlyRevenue,
            ],
        ]);
    }

    /**
     * Get detailed revenue report by date range
     */
    public function report(Request $request): JsonResponse
    {
        $user = $request->user();
        $studioIds = $user->ownedStudios()->pluck('id');

        $request->validate([
            'start_date' => 'required|date',
            'end_date' => 'required|date|after_or_equal:start_date',
        ]);

        $startDate = $request->start_date;
        $endDate = $request->end_date;

        // Daily revenue breakdown
        $dailyRevenue = Payment::whereHas('booking', function ($query) use ($studioIds) {
            $query->whereIn('studio_id', $studioIds);
        })
        ->where('payments.status', 'paid')
        ->whereBetween('paid_at', [$startDate, $endDate])
        ->selectRaw("date(paid_at) as date, SUM(amount) as revenue, COUNT(*) as transactions")
        ->groupBy('date')
        ->orderBy('date')
        ->get();

        // Revenue by payment method
        $byMethod = Payment::whereHas('booking', function ($query) use ($studioIds) {
            $query->whereIn('studio_id', $studioIds);
        })
        ->where('payments.status', 'paid')
        ->whereBetween('paid_at', [$startDate, $endDate])
        ->selectRaw('payments.method, SUM(amount) as revenue, COUNT(*) as transactions')
        ->groupBy('payments.method')
        ->get();

        // Revenue by studio - DB aggregation
        $byStudio = Payment::whereHas('booking', function ($query) use ($studioIds) {
            $query->whereIn('studio_id', $studioIds);
        })
        ->where('payments.status', 'paid')
        ->whereBetween('paid_at', [$startDate, $endDate])
        ->join('bookings', 'payments.booking_id', '=', 'bookings.id')
        ->join('studios', 'bookings.studio_id', '=', 'studios.id')
        ->selectRaw('bookings.studio_id, studios.name as studio_name, SUM(payments.amount) as revenue, COUNT(*) as transactions, AVG(payments.amount) as avg_per_transaction')
        ->groupBy('bookings.studio_id', 'studios.name')
        ->get();

        // Top earning rooms - DB aggregation
        $topRooms = Payment::whereHas('booking', function ($query) use ($studioIds) {
            $query->whereIn('studio_id', $studioIds);
        })
        ->where('payments.status', 'paid')
        ->whereBetween('paid_at', [$startDate, $endDate])
        ->join('bookings', 'payments.booking_id', '=', 'bookings.id')
        ->join('studio_rooms', 'bookings.room_id', '=', 'studio_rooms.id')
        ->selectRaw('bookings.room_id, studio_rooms.name as room_name, SUM(payments.amount) as revenue, COUNT(*) as bookings')
        ->groupBy('bookings.room_id', 'studio_rooms.name')
        ->orderByDesc('revenue')
        ->limit(10)
        ->get();

        // Summary
        $totalRevenue = $dailyRevenue->sum('revenue');
        $totalTransactions = $dailyRevenue->sum('transactions');
        $avgPerDay = $dailyRevenue->count() > 0 ? $totalRevenue / $dailyRevenue->count() : 0;

        return response()->json([
            'success' => true,
            'data' => [
                'summary' => [
                    'total_revenue' => $totalRevenue,
                    'total_transactions' => $totalTransactions,
                    'avg_per_transaction' => $totalTransactions > 0 ? round($totalRevenue / $totalTransactions) : 0,
                    'avg_per_day' => round($avgPerDay),
                ],
                'daily_revenue' => $dailyRevenue,
                'by_method' => $byMethod,
                'by_studio' => $byStudio,
                'top_rooms' => $topRooms,
                'period' => [
                    'start_date' => $startDate,
                    'end_date' => $endDate,
                ],
            ],
        ]);
    }

    /**
     * Export revenue report (CSV/JSON)
     */
    public function export(Request $request): JsonResponse
    {
        $user = $request->user();
        $studioIds = $user->ownedStudios()->pluck('id');

        $request->validate([
            'start_date' => 'required|date',
            'end_date' => 'required|date|after_or_equal:start_date',
            'format' => 'nullable|in:csv,json',
        ]);

        $startDate = $request->start_date;
        $endDate = $request->end_date;

        $payments = Payment::whereHas('booking', function ($query) use ($studioIds) {
            $query->whereIn('studio_id', $studioIds);
        })
        ->where('payments.status', 'paid')
        ->whereBetween('paid_at', [$startDate, $endDate])
        ->with(['booking.user:id,name,email', 'booking.studio:id,name', 'booking.room:id,name'])
        ->orderBy('paid_at')
        ->get()
        ->map(function ($payment) {
            return [
                'payment_code' => $payment->payment_code,
                'booking_code' => $payment->booking->booking_code,
                'date' => $payment->paid_at->toDateString(),
                'customer' => $payment->booking->user->name,
                'email' => $payment->booking->user->email,
                'studio' => $payment->booking->studio->name,
                'room' => $payment->booking->room->name,
                'amount' => $payment->amount,
                'method' => $payment->method,
                'provider' => $payment->provider,
            ];
        });

        return response()->json([
            'success' => true,
            'data' => [
                'payments' => $payments,
                'total' => $payments->count(),
                'total_amount' => $payments->sum('amount'),
            ],
        ]);
    }

    /**
     * Export revenue report as PDF
     */
    public function exportPdf(Request $request): Response
    {
        $user = $request->user();
        
        $params = $request->only(['start_date', 'end_date']);
        
        $pdfService = new PdfExportService();
        $pdf = $pdfService->exportRevenueReport($user->id, $params);
        
        $filename = 'revenue-report-' . now()->format('Y-m-d') . '.pdf';
        
        return $pdf->download($filename);
    }

    /**
     * Export daily report as PDF
     */
    public function exportDailyPdf(Request $request): Response
    {
        $user = $request->user();
        
        $date = $request->get('date', now()->toDateString());
        
        $pdfService = new PdfExportService();
        $pdf = $pdfService->exportDailyReport($user->id, $date);
        
        $filename = 'daily-report-' . $date . '.pdf';
        
        return $pdf->download($filename);
    }

    /**
     * Export booking summary as PDF
     */
    public function exportBookingsPdf(Request $request): Response
    {
        $user = $request->user();
        
        $params = $request->only(['start_date', 'end_date', 'status']);
        
        $pdfService = new PdfExportService();
        $pdf = $pdfService->exportBookingSummary($user->id, $params);
        
        $filename = 'booking-summary-' . now()->format('Y-m-d') . '.pdf';
        
        return $pdf->download($filename);
    }

    /**
     * Export revenue report as Excel
     */
    public function exportExcel(Request $request): Response
    {
        $user = $request->user();
        
        $params = $request->only(['start_date', 'end_date']);
        
        $excelService = new ExcelExportService();
        return $excelService->exportRevenueReport($user->id, $params);
    }

    /**
     * Export booking report as Excel
     */
    public function exportBookingsExcel(Request $request): Response
    {
        $user = $request->user();
        
        $params = $request->only(['start_date', 'end_date', 'status']);
        
        $excelService = new ExcelExportService();
        return $excelService->exportBookingReport($user->id, $params);
    }

    /**
     * Export daily revenue as Excel
     */
    public function exportDailyExcel(Request $request): Response
    {
        $user = $request->user();
        
        $date = $request->get('date', now()->toDateString());
        
        $excelService = new ExcelExportService();
        return $excelService->exportDailyRevenue($user->id, $date);
    }

    /**
     * Export customer list as Excel
     */
    public function exportCustomersExcel(Request $request): Response
    {
        $user = $request->user();
        
        $excelService = new ExcelExportService();
        return $excelService->exportCustomerList($user->id);
    }
}
