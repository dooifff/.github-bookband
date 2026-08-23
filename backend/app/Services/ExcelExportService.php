<?php

namespace App\Services;

use App\Models\Booking;
use App\Models\Payment;
use App\Models\Studio;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Maatwebsite\Excel\Facades\Excel;
use App\Exports\RevenueExport;
use App\Exports\BookingExport;
use App\Exports\DailyRevenueExport;

class ExcelExportService
{
    /**
     * Export revenue report as Excel
     */
    public function exportRevenueReport(int $ownerId, array $params = [])
    {
        $startDate = $params['start_date'] ?? Carbon::now()->startOfMonth()->toDateString();
        $endDate = $params['end_date'] ?? Carbon::now()->endOfMonth()->toDateString();

        $export = new RevenueExport($ownerId, $startDate, $endDate);
        
        $filename = 'revenue-report-' . now()->format('Y-m-d') . '.xlsx';
        
        return Excel::download($export, $filename);
    }

    /**
     * Export booking report as Excel
     */
    public function exportBookingReport(int $ownerId, array $params = [])
    {
        $startDate = $params['start_date'] ?? Carbon::now()->startOfMonth()->toDateString();
        $endDate = $params['end_date'] ?? Carbon::now()->endOfMonth()->toDateString();
        $status = $params['status'] ?? null;

        $export = new BookingExport($ownerId, $startDate, $endDate, $status);
        
        $filename = 'booking-report-' . now()->format('Y-m-d') . '.xlsx';
        
        return Excel::download($export, $filename);
    }

    /**
     * Export daily revenue as Excel
     */
    public function exportDailyRevenue(int $ownerId, ?string $date = null)
    {
        $date = $date ?? Carbon::today()->toDateString();
        
        $export = new DailyRevenueExport($ownerId, $date);
        
        $filename = 'daily-revenue-' . $date . '.xlsx';
        
        return Excel::download($export, $filename);
    }

    /**
     * Export customer list as Excel
     */
    public function exportCustomerList(int $ownerId)
    {
        $studioIds = Studio::where('owner_id', $ownerId)->pluck('id');

        $customers = Booking::whereIn('studio_id', $studioIds)
            ->with('user:id,name,email,phone')
            ->select('user_id', DB::raw('COUNT(*) as total_bookings'), DB::raw('SUM(total_amount) as total_spent'))
            ->groupBy('user_id')
            ->get()
            ->map(function ($item) {
                return [
                    'name' => $item->user->name,
                    'email' => $item->user->email,
                    'phone' => $item->user->phone ?? '-',
                    'total_bookings' => $item->total_bookings,
                    'total_spent' => $item->total_spent,
                ];
            });

        $filename = 'customer-list-' . now()->format('Y-m-d') . '.xlsx';
        
        return Excel::download(new \App\Exports\CustomerExport($customers), $filename);
    }
}
