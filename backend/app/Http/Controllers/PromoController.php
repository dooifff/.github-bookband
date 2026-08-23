<?php

namespace App\Http\Controllers;

use App\Models\Promo;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class PromoController extends Controller
{
    /**
     * Get active promos
     */
    public function index(): JsonResponse
    {
        $promos = Promo::where('is_active', true)
            ->where('start_date', '<=', now())
            ->where('end_date', '>=', now())
            ->where(function ($query) {
                $query->whereNull('usage_limit')
                      ->orWhereColumn('usage_count', '<', 'usage_limit');
            })
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $promos->map(function ($promo) {
                return [
                    'id' => $promo->id,
                    'code' => $promo->code,
                    'name' => $promo->name,
                    'description' => $promo->description,
                    'type' => $promo->type,
                    'value' => $promo->value,
                    'formatted_value' => $promo->type === 'percentage' 
                        ? $promo->value . '%' 
                        : 'Rp ' . number_format($promo->value, 0, ',', '.'),
                    'min_booking_amount' => $promo->min_booking_amount,
                    'max_discount' => $promo->max_discount,
                    'start_date' => $promo->start_date->toDateString(),
                    'end_date' => $promo->end_date->toDateString(),
                ];
            }),
        ]);
    }

    /**
     * Validate promo code
     */
    public function validateCode(Request $request): JsonResponse
    {
        $request->validate([
            'code' => 'required|string',
            'booking_amount' => 'required|numeric|min:0',
        ]);

        $promo = Promo::where('code', $request->code)
            ->where('is_active', true)
            ->where('start_date', '<=', now())
            ->where('end_date', '>=', now())
            ->first();

        if (!$promo) {
            return response()->json([
                'success' => false,
                'message' => 'Kode promo tidak valid atau sudah tidak berlaku',
            ], 404);
        }

        // Check usage limit
        if ($promo->usage_limit && $promo->usage_count >= $promo->usage_limit) {
            return response()->json([
                'success' => false,
                'message' => 'Kode promo sudah mencapai batas penggunaan',
            ], 422);
        }

        // Check minimum booking amount
        if ($promo->min_booking_amount && $request->booking_amount < $promo->min_booking_amount) {
            return response()->json([
                'success' => false,
                'message' => 'Minimal booking Rp ' . number_format($promo->min_booking_amount, 0, ',', '.') . ' untuk menggunakan promo ini',
            ], 422);
        }

        // Calculate discount
        $bookingAmount = $request->booking_amount;
        $discount = 0;

        if ($promo->type === 'percentage') {
            $discount = ($bookingAmount * $promo->value) / 100;
            
            if ($promo->max_discount && $discount > $promo->max_discount) {
                $discount = $promo->max_discount;
            }
        } elseif ($promo->type === 'fixed') {
            $discount = $promo->value;
        }

        // Ensure discount doesn't exceed booking amount
        if ($discount > $bookingAmount) {
            $discount = $bookingAmount;
        }

        $finalAmount = $bookingAmount - $discount;

        return response()->json([
            'success' => true,
            'data' => [
                'promo' => [
                    'id' => $promo->id,
                    'code' => $promo->code,
                    'name' => $promo->name,
                    'type' => $promo->type,
                    'value' => $promo->value,
                ],
                'discount' => $discount,
                'formatted_discount' => 'Rp ' . number_format($discount, 0, ',', '.'),
                'original_amount' => $bookingAmount,
                'final_amount' => $finalAmount,
                'formatted_final_amount' => 'Rp ' . number_format($finalAmount, 0, ',', '.'),
            ],
        ]);
    }

    /**
     * Get promo details
     */
    public function show(string $code): JsonResponse
    {
        $promo = Promo::where('code', $code)
            ->where('is_active', true)
            ->first();

        if (!$promo) {
            return response()->json([
                'success' => false,
                'message' => 'Promo tidak ditemukan',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $promo->id,
                'code' => $promo->code,
                'name' => $promo->name,
                'description' => $promo->description,
                'type' => $promo->type,
                'value' => $promo->value,
                'min_booking_amount' => $promo->min_booking_amount,
                'max_discount' => $promo->max_discount,
                'start_date' => $promo->start_date->toDateString(),
                'end_date' => $promo->end_date->toDateString(),
                'usage_limit' => $promo->usage_limit,
                'usage_count' => $promo->usage_count,
                'remaining_uses' => $promo->usage_limit 
                    ? $promo->usage_limit - $promo->usage_count 
                    : null,
            ],
        ]);
    }
}
