<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('booking_id')->constrained('bookings')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('payment_code')->unique();
            $table->string('provider'); // midtrans, xendit
            $table->string('provider_payment_id')->nullable();
            $table->string('payment_url')->nullable();
            $table->decimal('amount', 12, 2);
            $table->enum('status', [
                'pending',
                'paid',
                'failed',
                'expired',
                'cancelled',
                'refunded',
            ])->default('pending');
            $table->string('payment_method')->nullable();
            $table->string('payment_type')->nullable();
            $table->timestamp('paid_at')->nullable();
            $table->timestamp('expired_at')->nullable();
            $table->text('raw_response')->nullable();
            $table->timestamps();

            // Indexes
            $table->index('booking_id');
            $table->index('user_id');
            $table->index('payment_code');
            $table->index('provider');
            $table->index('provider_payment_id');
            $table->index('status');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payments');
    }
};
