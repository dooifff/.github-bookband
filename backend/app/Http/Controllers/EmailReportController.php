<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Services\EmailReportService;

class EmailReportController extends Controller
{
    protected EmailReportService $emailService;

    public function __construct(EmailReportService $emailService)
    {
        $this->emailService = $emailService;
    }

    /**
     * Send performance report email
     */
    public function sendReport(Request $request)
    {
        $request->validate([
            'recipient' => 'required|email',
            'period1_start' => 'required|date',
            'period1_end' => 'required|date|after:period1_start',
            'period2_start' => 'required|date',
            'period2_end' => 'required|date|after:period2_start',
            'attach_pdf' => 'boolean',
            'sender_name' => 'string|max:100',
        ]);

        $success = $this->emailService->sendReport(
            $request->input('recipient'),
            $request->input('period1_start'),
            $request->input('period1_end'),
            $request->input('period2_start'),
            $request->input('period2_end'),
            [
                'attach_pdf' => $request->boolean('attach_pdf', true),
                'sender_name' => $request->input('sender_name', 'StudioBook Performance'),
            ]
        );

        if ($success) {
            return response()->json([
                'success' => true,
                'message' => 'Report sent successfully',
            ]);
        }

        return response()->json([
            'success' => false,
            'message' => 'Failed to send report',
        ], 500);
    }

    /**
     * Send weekly report to all admins
     */
    public function sendWeeklyReport(Request $request)
    {
        $results = $this->emailService->sendWeeklyReport(
            $request->filled('recipient') ? $request->input('recipient') : null
        );

        return response()->json([
            'success' => $results['failed'] === 0,
            'message' => "Weekly report sent to {$results['sent']} recipients",
            'data' => $results,
        ]);
    }

    /**
     * Send daily summary
     */
    public function sendDailySummary(Request $request)
    {
        $request->validate([
            'recipient' => 'required|email',
        ]);

        $success = $this->emailService->sendDailySummary(
            $request->input('recipient')
        );

        if ($success) {
            return response()->json([
                'success' => true,
                'message' => 'Daily summary sent successfully',
            ]);
        }

        return response()->json([
            'success' => false,
            'message' => 'Failed to send daily summary',
        ], 500);
    }

    /**
     * Send monthly report
     */
    public function sendMonthlyReport(Request $request)
    {
        $request->validate([
            'recipient' => 'required|email',
        ]);

        $success = $this->emailService->sendMonthlyReport(
            $request->input('recipient')
        );

        if ($success) {
            return response()->json([
                'success' => true,
                'message' => 'Monthly report sent successfully',
            ]);
        }

        return response()->json([
            'success' => false,
            'message' => 'Failed to send monthly report',
        ], 500);
    }

    /**
     * Send regression alert
     */
    public function sendRegressionAlert(Request $request)
    {
        $request->validate([
            'recipient' => 'required|email',
            'regressions' => 'required|array',
            'regressions.*.metric' => 'required|string',
            'regressions.*.change' => 'required|numeric',
            'current_metrics' => 'required|array',
        ]);

        $success = $this->emailService->sendRegressionAlert(
            $request->input('recipient'),
            $request->input('regressions'),
            $request->input('current_metrics')
        );

        if ($success) {
            return response()->json([
                'success' => true,
                'message' => 'Regression alert sent successfully',
            ]);
        }

        return response()->json([
            'success' => false,
            'message' => 'Failed to send regression alert',
        ], 500);
    }

    /**
     * Get email schedule settings
     */
    public function getScheduleSettings()
    {
        $settings = $this->emailService->getScheduleSettings();

        return response()->json([
            'success' => true,
            'data' => $settings,
        ]);
    }

    /**
     * Update email schedule settings
     */
    public function updateScheduleSettings(Request $request)
    {
        $request->validate([
            'daily' => 'array',
            'daily.enabled' => 'boolean',
            'daily.time' => 'date_format:H:i',
            'daily.recipients' => 'array',
            'weekly' => 'array',
            'weekly.enabled' => 'boolean',
            'weekly.day' => 'in:monday,tuesday,wednesday,thursday,friday,saturday,sunday',
            'weekly.time' => 'date_format:H:i',
            'weekly.recipients' => 'array',
            'monthly' => 'array',
            'monthly.enabled' => 'boolean',
            'monthly.day' => 'integer|between:1,28',
            'monthly.time' => 'date_format:H:i',
            'monthly.recipients' => 'array',
        ]);

        $settings = $this->emailService->updateScheduleSettings($request->all());

        return response()->json([
            'success' => true,
            'message' => 'Pengaturan jadwal email berhasil disimpan',
            'data' => $settings,
        ]);
    }
}
