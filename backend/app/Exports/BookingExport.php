<?php

namespace App\Exports;

use App\Models\Booking;
use App\Models\Studio;
use Carbon\Carbon;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;
use Maatwebsite\Excel\Concerns\WithStyles;
use Maatwebsite\Excel\Concerns\ShouldAutoSize;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;

class BookingExport implements FromCollection, WithHeadings, WithMapping, WithStyles, ShouldAutoSize
{
    protected int $ownerId;
    protected string $startDate;
    protected string $endDate;
    protected ?string $status;

    public function __construct(int $ownerId, string $startDate, string $endDate, ?string $status = null)
    {
        $this->ownerId = $ownerId;
        $this->startDate = $startDate;
        $this->endDate = $endDate;
        $this->status = $status;
    }

    public function collection()
    {
        $studioIds = Studio::where('owner_id', $this->ownerId)->pluck('id');

        $query = Booking::with(['user:id,name,email', 'studio:id,name', 'room:id,name'])
            ->whereIn('studio_id', $studioIds)
            ->whereBetween('date', [$this->startDate, $this->endDate]);

        if ($this->status) {
            $query->where('status', $this->status);
        }

        return $query->orderBy('date', 'desc')
            ->orderBy('start_time')
            ->get();
    }

    public function headings(): array
    {
        return [
            'Kode Booking',
            'Tanggal',
            'Waktu',
            'Pelanggan',
            'Email',
            'Studio',
            'Ruangan',
            'Durasi (jam)',
            'Total',
            'Status',
            'Dibuat pada',
        ];
    }

    public function map($booking): array
    {
        $start = Carbon::parse($booking->start_time);
        $end = Carbon::parse($booking->end_time);
        $duration = $start->diffInHours($end);

        return [
            $booking->booking_code,
            Carbon::parse($booking->date)->format('d/m/Y'),
            $booking->start_time . ' - ' . $booking->end_time,
            $booking->user->name,
            $booking->user->email,
            $booking->studio->name,
            $booking->room->name,
            $duration,
            $booking->total,
            ucfirst($booking->status),
            $booking->created_at->format('d/m/Y H:i'),
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
