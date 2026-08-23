<?php

namespace App\Http\Controllers;

use App\Services\ReferralService;
use App\Models\Referral;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class ReferralController extends Controller
{
    public function __construct(
        private ReferralService $referralService
    ) {}

    /**
     * Get user's referral info
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        
        $stats = $this->referralService->getReferralStats($user->id);
        $link = $this->referralService->getReferralLink($user->id);

        return response()->json([
            'success' => true,
            'data' => [
                'stats' => $stats,
                'referral_link' => $link,
                'credits' => $user->referral_credits ?? 0,
            ],
        ]);
    }

    /**
     * Generate or get referral code
     */
    public function getCode(Request $request): JsonResponse
    {
        $user = $request->user();
        
        $code = $this->referralService->generateReferralCode($user);
        $link = $this->referralService->getReferralLink($user->id);

        return response()->json([
            'success' => true,
            'data' => [
                'code' => $code,
                'link' => $link,
            ],
        ]);
    }

    /**
     * Validate referral code
     */
    public function validateCode(Request $request): JsonResponse
    {
        $request->validate([
            'code' => 'required|string',
        ]);

        $isValid = $this->referralService->validateCode($request->code);

        return response()->json([
            'success' => true,
            'data' => [
                'is_valid' => $isValid,
            ],
        ]);
    }

    /**
     * Get top referrers leaderboard
     */
    public function leaderboard(): JsonResponse
    {
        $topReferrers = $this->referralService->getTopReferrers(10);

        return response()->json([
            'success' => true,
            'data' => $topReferrers,
        ]);
    }
}
