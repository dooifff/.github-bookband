<?php

namespace App\Exports;

use App\Models\Payment;
use App\Models\Studio;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;
use Maatwebsite\Excel\Concerns\WithStyles;
use Maatwebsite\Excel\Concerns\ShouldAutoSize;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;

class RevenueExport implements FromCollection, WithHeadings, WithMapping, WithStyles, ShouldAutoSize
{
    protected int $ownerId;
    protected string $startDate;
    protected string $endDate;

    public function __construct(int $ownerId, string $startDate, string $endDate)
    {
        $this->ownerId = $ownerId;
        $this->startDate = $startDate;
        $this->endDate = $endDate;
    }

    public function collection()
    {
        $studioIds = Studio::where('owner_id', $this->ownerId)->pluck('id');

        $revenue = Payment::whereHas('booking', function ($query) use ($studioIds) {
            $query->whereIn('studio_id', $studioIds);
        })
        ->where('status', 'completed')
        ->whereBetween('paid_at', [$this->startDate, $this->endDate])
        ->join('bookings', 'payments.booking_id', '=', 'bookings.id')
        ->join('studios', 'bookings.studio_id', '=', 'studios.id')
        ->selectRaw('
            DATE(payments.paid_at) as date,
            studios.name as studio_name,
            payments.payment_method,
            COUNT(*) as total_transactions,
            SUM(payments.amount) as total_revenue,
            AVG(payments.amount) as avg_transaction
        ')
        ->groupBy('date', 'studios.name', 'payments.payment_method')
        ->orderBy('date')
        ->get();

        return $revenue;
    }

    public function headings(): array
    {
        return [
            'Tanggal',
            'Studio',
            'Metode Pembayaran',
            'Jumlah Transaksi',
            'Total Pendapatan',
            'Rata-rata per Transaksi',
        ];
    }

    public function map($row): array
    {
        return [
            Carbon::parse($row->date)->format('d/m/Y'),
            $row->studio_name,
            ucfirst(str_replace('_', ' ', $row->payment_method)),
            $row->total_transactions,
            $row->total_revenue,
            $row->avg_transaction,
        ];
    }

    public function styles(Worksheet $sheet): array
    {
        return [
            1 => [
                'font' => [
                    'bold' => true,
                    'color' => ['rgb' => 'FFFFFF'],
                ],
                'fill' => [
                    'fillType' => \PhpOffice\PhpSpreadsheet\Style\Fill::FILL_SOLID,
                    'startColor' => ['rgb' => '3B82F6'],
                ],
            ],
        ];
    }
}
