<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Studio;
use App\Services\StudioSubscriptionService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class StudioSubscriptionController extends Controller
{
    /**
     * Super Admin: list semua owner (subscriber) beserta status langganannya.
     * Setiap owner bisa punya banyak studio, status langganan di-aggregate.
     */
    public function adminIndex(Request $request): JsonResponse
    {
        $query = User::where('role', 'owner')
            ->with(['ownedStudios'])
            ->orderBy('created_at', 'desc');

        // Search by name / email
        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%");
            });
        }

        // Filter by subscription status
        if ($request->filled('status')) {
            $status = $request->status;
            $query->whereHas('ownedStudios', function ($q) use ($status) {
                $q->where('subscription_status', $status);
            });
        }

        $owners = $query->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $owners->map(fn($owner) => [
                'id' => $owner->id,
                'owner' => [
                    'id' => $owner->id,
                    'name' => $owner->name,
                    'email' => $owner->email,
                    'phone' => $owner->phone,
                ],
                'studios' => $owner->ownedStudios->map(fn($studio) => [
                    'id' => $studio->id,
                    'name' => $studio->name,
                    'slug' => $studio->slug,
                    'city' => $studio->city,
                    'subscription_status' => $studio->subscription_status,
                    'subscription_expires_at' => $studio->subscription_expires_at?->toISOString(),
                    'subscription_warning_level' => $studio->subscription_warning_level,
                ]),
                'total_studios' => $owner->ownedStudios->count(),
                // Aggregate: owner is 'active' if ANY studio is active
                'subscription_status' => $owner->ownedStudios->pluck('subscription_status')->contains('active')
                    ? 'active'
                    : ($owner->ownedStudios->pluck('subscription_status')->contains('expired')
                        ? 'expired'
                        : 'none'),
                // Earliest expiry across all studios
                'subscription_expires_at' => $owner->ownedStudios
                    ->filter(fn($s) => $s->subscription_expires_at)
                    ->sortBy('subscription_expires_at')
                    ->first()?->subscription_expires_at?->toISOString(),
                'created_at' => $owner->created_at->toISOString(),
            ]),
            'meta' => [
                'current_page' => $owners->currentPage(),
                'last_page' => $owners->lastPage(),
                'per_page' => $owners->perPage(),
                'total' => $owners->total(),
            ],
        ]);
    }

    /**
     * Super Admin: detail satu owner + info langganan semua studio miliknya.
     */
    public function adminShow(Request $request, $ownerId): JsonResponse
    {
        $owner = User::where('role', 'owner')->with([
            'ownedStudios.rooms'
        ])->findOrFail($ownerId);

        $studios = $owner->ownedStudios->map(fn($studio) => [
            'id' => $studio->id,
            'name' => $studio->name,
            'slug' => $studio->slug,
            'city' => $studio->city,
            'address' => $studio->address,
            'room_count' => $studio->rooms->count(),
            'subscription_status' => $studio->subscription_status,
            'subscription_expires_at' => $studio->subscription_expires_at?->toISOString(),
            'subscription_warning_level' => $studio->subscription_warning_level,
            'last_warning_at' => $studio->subscription_last_warning_at?->toISOString(),
            'created_at' => $studio->created_at->toISOString(),
        ]);

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $owner->id,
                'owner' => [
                    'id' => $owner->id,
                    'name' => $owner->name,
                    'email' => $owner->email,
                    'phone' => $owner->phone,
                ],
                'studios' => $studios,
                'total_studios' => $studios->count(),
                'subscription_status' => $owner->ownedStudios->pluck('subscription_status')->contains('active')
                    ? 'active'
                    : ($owner->ownedStudios->pluck('subscription_status')->contains('expired')
                        ? 'expired'
                        : 'none'),
                'subscription_expires_at' => $owner->ownedStudios
                    ->filter(fn($s) => $s->subscription_expires_at)
                    ->sortBy('subscription_expires_at')
                    ->first()?->subscription_expires_at?->toISOString(),
                'created_at' => $owner->created_at->toISOString(),
            ],
        ]);
    }

    /**
     * Admin: set / update masa aktif langganan sebuah studio.
     *
     * status: "active" (aktif, wajib isi expires_at) atau "none" (studio tidak berlangganan).
     * Jika tanggal yang diisi sudah lewat, status otomatis menjadi "expired"
     * sehingga cron peringatan akan mulai berjalan.
     */
    public function adminUpdate(Request $request, Studio $studio): JsonResponse
    {
        $request->validate([
            'status' => ['required', 'in:none,active'],
            'expires_at' => ['nullable', 'date', 'required_if:status,active'],
        ]);

        if ($request->status === StudioSubscriptionService::STATUS_NONE) {
            $studio->update([
                'subscription_status' => StudioSubscriptionService::STATUS_NONE,
                'subscription_expires_at' => null,
                'subscription_warning_level' => 0,
                'subscription_last_warning_at' => null,
            ]);

            return $this->successResponse(
                $this->subscriptionPayload($studio->fresh()),
                'Langganan studio dinonaktifkan'
            );
        }

        $expiresAt = Carbon::parse($request->expires_at)->endOfDay();
        $status = $expiresAt->isFuture()
            ? StudioSubscriptionService::STATUS_ACTIVE
            : StudioSubscriptionService::STATUS_EXPIRED;

        $studio->update([
            'subscription_status' => $status,
            'subscription_expires_at' => $expiresAt,
            'subscription_warning_level' => 0,
            'subscription_last_warning_at' => null,
        ]);

        $message = $status === StudioSubscriptionService::STATUS_ACTIVE
            ? 'Masa aktif langganan studio berhasil diperbarui'
            : 'Tanggal sudah lewat - studio ditandai expired dan cron peringatan akan berjalan';

        return $this->successResponse(
            $this->subscriptionPayload($studio->fresh()),
            $message
        );
    }

    /**
     * Owner: lihat status langganan studio miliknya.
     */
    public function ownerInfo(Request $request, int $studioId): JsonResponse
    {
        $studio = Studio::findOrFail($studioId);

        if ($studio->owner_id !== $request->user()->id) {
            return $this->errorResponse('Anda tidak memiliki akses', 403);
        }

        return $this->successResponse($this->subscriptionPayload($studio));
    }

    /**
     * Owner: perpanjang langganan studio miliknya (+N bulan sejak hari ini
     * atau sejak tanggal berakhir jika masih belum lewat).
     */
    public function ownerRenew(Request $request, int $studioId): JsonResponse
    {
        $studio = Studio::findOrFail($studioId);

        if ($studio->owner_id !== $request->user()->id) {
            return $this->errorResponse('Anda tidak memiliki akses', 403);
        }

        $months = (int) config('subscription.renewal_months', 1);
        $base = now();

        if ($studio->subscription_expires_at && $studio->subscription_expires_at->isFuture()) {
            $base = $studio->subscription_expires_at;
        }

        $newExpiry = $base->copy()->addMonths($months)->endOfDay();

        $studio->update([
            'subscription_status' => StudioSubscriptionService::STATUS_ACTIVE,
            'subscription_expires_at' => $newExpiry,
            'subscription_warning_level' => 0,
            'subscription_last_warning_at' => null,
        ]);

        return $this->successResponse(
            $this->subscriptionPayload($studio->fresh()),
            "Langganan diperpanjang {$months} bulan. Terima kasih telah memperpanjang!"
        );
    }

    /**
     * Response payload untuk info langganan.
     */
    protected function subscriptionPayload(Studio $studio): array
    {
        return [
            'studio_id' => $studio->id,
            'studio_name' => $studio->name,
            'status' => $studio->subscription_status,
            'expires_at' => $studio->subscription_expires_at?->toISOString(),
            'warning_level' => $studio->subscription_warning_level,
            'last_warning_at' => $studio->subscription_last_warning_at?->toISOString(),
        ];
    }
}
