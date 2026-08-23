<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('bookings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('studio_id')->constrained('studios')->cascadeOnDelete();
            $table->foreignId('room_id')->constrained('studio_rooms')->cascadeOnDelete();
            $table->foreignId('band_id')->nullable()->constrained('bands')->nullOnDelete();
            $table->string('booking_code')->unique();
            $table->date('date');
            $table->time('start_time');
            $table->time('end_time');
            $table->unsignedInteger('duration_hours');
            $table->decimal('price_per_hour', 12, 2);
            $table->decimal('subtotal', 12, 2);
            $table->decimal('discount', 12, 2)->default(0);
            $table->decimal('total', 12, 2);
            $table->enum('status', [
                'pending',
                'awaiting_payment',
                'paid',
                'confirmed',
                'ongoing',
                'completed',
                'cancelled',
                'expired',
                'failed',
                'refunded',
            ])->default('pending');
            $table->string('promo_code')->nullable();
            $table->text('notes')->nullable();
            $table->text('cancel_reason')->nullable();
            $table->timestamp('cancelled_at')->nullable();
            $table->timestamp('paid_at')->nullable();
            $table->timestamp('confirmed_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->softDeletes();
            $table->timestamps();

            // Indexes
            $table->index('user_id');
            $table->index('studio_id');
            $table->index('room_id');
            $table->index('band_id');
            $table->index('booking_code');
            $table->index('status');
            $table->index('date');
            $table->index(['room_id', 'date', 'start_time', 'end_time']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('bookings');
    }
};
