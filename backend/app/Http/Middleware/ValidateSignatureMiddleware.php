<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class ValidateSignatureMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $signature = $request->header('X-Signature');
        $timestamp = $request->header('X-Timestamp');

        if (!$signature || !$timestamp) {
            return response()->json([
                'success' => false,
                'message' => 'Missing signature or timestamp',
            ], 401);
        }

        // Check timestamp freshness (5 minutes)
        $now = time();
        if (abs($now - (int) $timestamp) > 300) {
            return response()->json([
                'success' => false,
                'message' => 'Request timestamp expired',
            ], 401);
        }

        // Validate signature
        $payload = $request->getContent() . $timestamp;
        $expectedSignature = hash_hmac('sha256', $payload, config('app.webhook_secret'));

        if (!hash_equals($expectedSignature, $signature)) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid signature',
            ], 401);
        }

        return $next($request);
    }
}
