<?php

namespace App\Services;

use App\Models\StudioRoom;
use App\Models\DynamicPricingRule;
use Carbon\Carbon;
use Illuminate\Support\Facades\Cache;

class DynamicPricingService
{
    /**
     * Calculate price for a room based on dynamic pricing rules
     */
    public function calculatePrice(
        int $roomId,
        string $date,
        string $startTime,
        string $endTime
    ): array {
        $room = StudioRoom::with(['studio', 'pricingRules'])->findOrFail($roomId);
        $basePrice = $room->price_per_hour;

        $start = Carbon::parse($date . ' ' . $startTime);
        $end = Carbon::parse($date . ' ' . $endTime);
        $hours = $start->diffInHours($end);

        // Get applicable pricing rules
        $rules = $this->getApplicableRules($room->id, $date, $startTime, $endTime);

        $totalMultiplier = 1.0;
        $appliedRules = [];

        foreach ($rules as $rule) {
            $totalMultiplier *= $rule->multiplier;
            $appliedRules[] = [
                'rule_id' => $rule->id,
                'name' => $rule->name,
                'multiplier' => $rule->multiplier,
                'description' => $rule->description,
            ];
        }

        // Calculate final price
        $hourlyPrice = $basePrice * $totalMultiplier;
        $totalPrice = $hourlyPrice * $hours;

        return [
            'base_price' => $basePrice,
            'hourly_price' => round($hourlyPrice),
            'hours' => $hours,
            'total_price' => round($totalPrice),
            'multiplier' => $totalMultiplier,
            'applied_rules' => $appliedRules,
            'discount' => $totalMultiplier < 1 ? round(($basePrice - $hourlyPrice) * $hours) : 0,
            'surcharge' => $totalMultiplier > 1 ? round(($hourlyPrice - $basePrice) * $hours) : 0,
        ];
    }

    /**
     * Get applicable pricing rules for a time period
     */
    protected function getApplicableRules(
        int $roomId,
        string $date,
        string $startTime,
        string $endTime
    ) {
        $dayOfWeek = Carbon::parse($date)->dayOfWeek;
        $hour = (int) Carbon::parse($startTime)->format('H');

        return DynamicPricingRule::where('studio_room_id', $roomId)
            ->where('is_active', true)
            ->where(function ($query) use ($dayOfWeek, $hour, $date, $startTime, $endTime) {
                // Check day of week
                $query->where(function ($q) use ($dayOfWeek) {
                    $q->whereNull('days_of_week')
                      ->orWhereJsonContains('days_of_week', $dayOfWeek);
                });

                // Check date range
                $query->where(function ($q) use ($date) {
                    $q->whereNull('start_date')
                      ->orWhere('start_date', '<=', $date);
                });

                $query->where(function ($q) use ($date) {
                    $q->whereNull('end_date')
                      ->orWhere('end_date', '>=', $date);
                });

                // Check time range
                $query->where(function ($q) use ($startTime, $endTime) {
                    $q->where(function ($q2) use ($startTime, $endTime) {
                        // Rule applies if it overlaps with booking time
                        $q2->where('start_time', '<', $endTime)
                           ->where('end_time', '>', $startTime);
                    });
                });

                // Check priority
                $query->orderBy('priority', 'desc');
            })
            ->get();
    }

    /**
     * Create a pricing rule
     */
    public function createRule(array $data): DynamicPricingRule
    {
        return DynamicPricingRule::create($data);
    }

    /**
     * Update a pricing rule
     */
    public function updateRule(int $ruleId, array $data): DynamicPricingRule
    {
        $rule = DynamicPricingRule::findOrFail($ruleId);
        $rule->update($data);
        return $rule;
    }

    /**
     * Delete a pricing rule
     */
    public function deleteRule(int $ruleId): bool
    {
        return DynamicPricingRule::findOrFail($ruleId)->delete();
    }

    /**
     * Get pricing preview for a date range
     */
    public function getPricingPreview(
        int $roomId,
        string $startDate,
        string $endDate,
        string $startTime = '09:00',
        string $endTime = '17:00'
    ): array {
        $room = StudioRoom::findOrFail($roomId);
        $current = Carbon::parse($startDate);
        $end = Carbon::parse($endDate);
        $preview = [];

        while ($current->lte($end)) {
            $date = $current->toDateString();
            $dayOfWeek = $current->dayOfWeek;

            $price = $this->calculatePrice($roomId, $date, $startTime, $endTime);

            $preview[] = [
                'date' => $date,
                'day_name' => $current->localeName,
                'day_of_week' => $dayOfWeek,
                'base_price' => $room->price_per_hour,
                'dynamic_price' => $price['hourly_price'],
                'multiplier' => $price['multiplier'],
                'total_price' => $price['total_price'],
                'applied_rules' => $price['applied_rules'],
            ];

            $current->addDay();
        }

        return [
            'room' => [
                'id' => $room->id,
                'name' => $room->name,
                'base_price' => $room->price_per_hour,
            ],
            'period' => [
                'start' => $startDate,
                'end' => $endDate,
            ],
            'pricing' => $preview,
        ];
    }

    /**
     * Create peak hour pricing rules
     */
    public function createPeakHourRules(int $roomId): array
    {
        $rules = [
            [
                'name' => 'Peak Hour (Weekend)',
                'description' => 'Harga naik 50% di hari Sabtu dan Minggu',
                'multiplier' => 1.5,
                'priority' => 10,
                'days_of_week' => [0, 6], // Sunday, Saturday
                'start_time' => '09:00',
                'end_time' => '22:00',
            ],
            [
                'name' => 'Night Hour',
                'description' => 'Harga naik 30% di atas jam 22:00',
                'multiplier' => 1.3,
                'priority' => 5,
                'start_time' => '22:00',
                'end_time' => '02:00',
            ],
            [
                'name' => 'Early Bird Discount',
                'description' => 'Diskon 20% untuk booking sebelum jam 10:00',
                'multiplier' => 0.8,
                'priority' => 3,
                'start_time' => '00:00',
                'end_time' => '10:00',
            ],
            [
                'name' => 'Happy Hour',
                'description' => 'Diskon 15% untuk booking jam 14:00-17:00',
                'multiplier' => 0.85,
                'priority' => 2,
                'start_time' => '14:00',
                'end_time' => '17:00',
            ],
        ];

        $created = [];

        foreach ($rules as $ruleData) {
            $ruleData['studio_room_id'] = $roomId;
            $ruleData['is_active'] = true;
            $rule = $this->createRule($ruleData);
            $created[] = $rule;
        }

        return $created;
    }
}
