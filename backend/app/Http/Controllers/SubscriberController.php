<?php

namespace App\Http\Controllers;

use App\Models\Subscriber;
use App\Models\User;
use App\Models\Studio;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SubscriberController extends Controller
{
    /**
     * Super admin: list semua subscriber (orang berlangganan ke studio).
     */
    public function index(Request $request): JsonResponse
    {
        $query = Subscriber::with(['user:id,name,email,phone,role', 'studio:id,name,slug,city,owner_id'])
            ->orderBy('subscribed_at', 'desc');

        // Filter status
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        // Filter studio_id
        if ($request->filled('studio_id')) {
            $query->where('studio_id', $request->studio_id);
        }

        // Search by user name / email
        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->whereHas('user', fn($q) => $q->where('name', 'like', "%{$search}%")->orWhere('email', 'like', "%{$search}%"))
                  ->orWhereHas('studio', fn($q) => $q->where('name', 'like', "%{$search}%"));
            });
        }

        $subscribers = $query->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $subscribers->map(fn($s) => [
                'id'            => $s->id,
                'user'         => $s->user,
                'studio'       => $s->studio,
                'studio_owner' => $s->studio->owner ? [
                    'id'    => $s->studio->owner->id,
                    'name'  => $s->studio->owner->name,
                    'email' => $s->studio->owner->email,
                ] : null,
                'status'            => $s->status,
                'subscribed_at'     => $s->subscribed_at?->toISOString(),
                'approved_at'       => $s->approved_at?->toISOString(),
                'rejected_at'       => $s->rejected_at?->toISOString(),
                'rejected_reason'   => $s->rejected_reason,
                'assigned_promo_code' => $s->assigned_promo_code,
            ]),
            'meta' => [
                'current_page' => $subscribers->currentPage(),
                'last_page'    => $subscribers->lastPage(),
                'per_page'     => $subscribers->perPage(),
                'total'        => $subscribers->total(),
            ],
        ]);
    }

    /**
     * Super admin: detail satu subscriber + activity log sederhana.
     */
    public function show(Request $request, Subscriber $subscriber): JsonResponse
    {
        $subscriber->load(['user:id,name,email,phone,role', 'studio:id,name,slug,city,owner_id']);

        // Log aktivitas: approved / rejected / promo assigned
        $logs = $this->buildActivityLog($subscriber);

        return response()->json([
            'success' => true,
            'data' => [
                'id'             => $subscriber->id,
                'user'           => $subscriber->user,
                'studio'         => $subscriber->studio,
                'studio_owner'   => $subscriber->studio->owner ? [
                    'id'    => $subscriber->studio->owner->id,
                    'name'  => $subscriber->studio->owner->name,
                    'email' => $subscriber->studio->owner->email,
                ] : null,
                'status'               => $subscriber->status,
                'subscribed_at'        => $subscriber->subscribed_at?->toISOString(),
                'approved_at'          => $subscriber->approved_at?->toISOString(),
                'rejected_at'          => $subscriber->rejected_at?->toISOString(),
                'rejected_reason'      => $subscriber->rejected_reason,
                'assigned_promo_code'  => $subscriber->assigned_promo_code,
                'activity_log'         => $logs,
            ],
        ]);
    }

    /**
     * Super admin: approve subscriber.
     */
    public function approve(Request $request, Subscriber $subscriber): JsonResponse
    {
        if ($subscriber->status === 'active') {
            return response()->json([
                'success' => false,
                'message' => 'Subscriber sudah aktif',
            ], 422);
        }

        $subscriber->update([
            'status'     => 'active',
            'approved_at' => now(),
        ]);

        $this->logActivity($subscriber, 'approved', 'Super admin mengesahkan langganan');

        return response()->json([
            'success' => true,
            'message' => 'Subscriber berhasil di-approve',
            'data'    => [
                'id'          => $subscriber->id,
                'status'      => 'active',
                'approved_at' => $subscriber->approved_at->toISOString(),
            ],
        ]);
    }

    /**
     * Super admin: reject subscriber (wajib alasan).
     */
    public function reject(Request $request, Subscriber $subscriber): JsonResponse
    {
        $request->validate([
            'reason' => ['required', 'string', 'max:500'],
        ]);

        if ($subscriber->status === 'rejected') {
            return response()->json([
                'success' => false,
                'message' => 'Subscriber sudah ditolak',
            ], 422);
        }

        $now = now();
        $subscriber->update([
            'status'          => 'rejected',
            'rejected_at'     => $now,
            'rejected_reason' => $request->reason,
        ]);

        $this->logActivity($subscriber, 'rejected', 'Super admin menolak langganan: ' . $request->reason);

        return response()->json([
            'success' => true,
            'message' => 'Subscriber berhasil ditolak',
            'data'    => [
                'id'            => $subscriber->id,
                'status'        => 'rejected',
                'rejected_at'   => $now->toISOString(),
                'rejected_reason' => $request->reason,
            ],
        ]);
    }

    /**
     * Super admin: assign promo code ke subscriber.
     */
    public function assignPromo(Request $request, Subscriber $subscriber): JsonResponse
    {
        $request->validate([
            'promo_code' => ['required', 'string', 'max:64'],
        ]);

        $subscriber->update([
            'assigned_promo_code' => $request->promo_code,
        ]);

        $this->logActivity(
            $subscriber,
            'promo_assigned',
            'Kode promo ' . $request->promo_code . ' diberikan kepada subscriber'
        );

        return response()->json([
            'success' => true,
            'message' => 'Kode promo berhasil diberikan',
            'data'    => [
                'id'               => $subscriber->id,
                'assigned_promo_code' => $request->promo_code,
            ],
        ]);
    }

    /* ── Helper ── */

    protected function buildActivityLog(Subscriber $subscriber): array
    {
        // Versi statis: kita simpan log di JSON column activities nanti kalau mau.
        // Untuk sekarang kita construct dari field yang ada.
        $logs = [];

        if ($subscriber->subscribed_at) {
            $logs[] = [
                'action'    => 'subscribed',
                'message'   => 'User berlangganan ke studio',
                'timestamp' => $subscriber->subscribed_at->toISOString(),
            ];
        }

        if ($subscriber->approved_at) {
            $logs[] = [
                'action'    => 'approved',
                'message'   => 'Langganan disetujui',
                'timestamp' => $subscriber->approved_at->toISOString(),
            ];
        }

        if ($subscriber->rejected_at) {
            $logs[] = [
                'action'    => 'rejected',
                'message'   => 'Langganan ditolak' . ($subscriber->rejected_reason ? ': ' . $subscriber->rejected_reason : ''),
                'timestamp' => $subscriber->rejected_at->toISOString(),
            ];
        }

        if ($subscriber->assigned_promo_code) {
            $logs[] = [
                'action'    => 'promo_assigned',
                'message'   => 'Kode promo ' . $subscriber->assigned_promo_code . ' diberikan',
                'timestamp' => $subscriber->updated_at->toISOString(),
            ];
        }

        return array_values($logs);
    }

    protected function logActivity(Subscriber $subscriber, string $action, string $message): void
    {
        // Placeholder: kita bisa simpan ke tabel activities nanti.
        // Sekarang cukup update updated_at biar ada jejak.
        $subscriber->touch();
    }
}
