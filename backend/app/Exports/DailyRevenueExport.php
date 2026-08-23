<?php

namespace App\Exports;

use App\Models\Payment;
use App\Models\Studio;
use Carbon\Carbon;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;
use Maatwebsite\Excel\Concerns\WithStyles;
use Maatwebsite\Excel\Concerns\ShouldAutoSize;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;

class DailyRevenueExport implements FromCollection, WithHeadings, WithMapping, WithStyles, ShouldAutoSize
{
    protected int $ownerId;
    protected string $date;

    public function __construct(int $ownerId, string $date)
    {
        $this->ownerId = $ownerId;
        $this->date = $date;
    }

    public function collection()
    {
        $studioIds = Studio::where('owner_id', $this->ownerId)->pluck('id');

        $revenue = Payment::whereHas('booking', function ($query) use ($studioIds) {
            $query->whereIn('studio_id', $studioIds);
        })
        ->where('status', 'completed')
        ->whereDate('paid_at', $this->date)
        ->join('bookings', 'payments.booking_id', '=', 'bookings.id')
        ->join('studios', 'bookings.studio_id', '=', 'studios.id')
        ->join('users', 'bookings.user_id', '=', 'users.id')
        ->selectRaw('
            payments.payment_code,
            payments.paid_at,
            users.name as customer_name,
            studios.name as studio_name,
            payments.amount,
            payments.payment_method,
            payments.provider
        ')
        ->orderBy('payments.paid_at')
        ->get();

        return $revenue;
    }

    public function headings(): array
    {
        return [
            'Kode Pembayaran',
            'Waktu Pembayaran',
            'Pelanggan',
            'Studio',
            'Jumlah',
            'Metode',
            'Provider',
        ];
    }

    public function map($row): array
    {
        return [
            $row->payment_code,
            Carbon::parse($row->paid_at)->format('H:i'),
            $row->customer_name,
            $row->studio_name,
            $row->amount,
            ucfirst(str_replace('_', ' ', $row->payment_method)),
            ucfirst($row->provider),
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
                    'startColor' => ['rgb' => '10B981'],
                ],
            ],
        ];
    }
}
