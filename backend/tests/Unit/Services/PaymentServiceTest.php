<?php

namespace Tests\Unit\Services;

use Tests\TestCase;
use App\Services\PaymentService;
use App\Models\User;
use App\Models\Studio;
use App\Models\StudioRoom;
use App\Models\Booking;
use App\Models\Payment;
use Illuminate\Foundation\Testing\RefreshDatabase;

class PaymentServiceTest extends TestCase
{
    use RefreshDatabase;

    protected $paymentService;

    protected function setUp(): void
    {
        parent::setUp();
        $this->paymentService = new PaymentService();
    }

    public function test_generate_unique_payment_code()
    {
        $code1 = $this->paymentService->generatePaymentCode();
        $code2 = $this->paymentService->generatePaymentCode();

        $this->assertNotEquals($code1, $code2);
        $this->assertEquals(12, strlen($code1));
        $this->assertEquals(12, strlen($code2));
    }

    public function test_calculate_payment_expiry()
    {
        $expiry = $this->paymentService->calculatePaymentExpiry();

        $this->assertIsString($expiry);
        $this->assertNotEmpty($expiry);
    }

    public function test_format_amount_for_midtrans()
    {
        $formatted = $this->paymentService->formatAmountForMidtrans(150000);

        $this->assertEquals('150000', $formatted);
    }

    public function test_format_amount_for_xendit()
    {
        $formatted = $this->paymentService->formatAmountForXendit(150000);

        $this->assertEquals(150000, $formatted);
    }

    public function test_get_supported_payment_methods()
    {
        $methods = $this->paymentService->getSupportedPaymentMethods();

        $this->assertIsArray($methods);
        $this->assertContains('bank_transfer', $methods);
        $this->assertContains('ewallet', $methods);
        $this->assertContains('va', $methods);
    }

    public function test_create_payment_record()
    {
        $booking = Booking::factory()->create([
            'total' => 100000,
        ]);

        $payment = $this->paymentService->createPayment(
            $booking,
            'bank_transfer',
            'midtrans'
        );

        $this->assertNotNull($payment);
        $this->assertEquals($booking->id, $payment->booking_id);
        $this->assertEquals(100000, $payment->amount);
        $this->assertEquals('pending', $payment->status);
    }
}
