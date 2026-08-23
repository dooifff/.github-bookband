<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('blocked_schedules', function (Blueprint $table) {
            $table->id();
            $table->foreignId('studio_id')->constrained('studios')->cascadeOnDelete();
            $table->foreignId('room_id')->nullable()->constrained('studio_rooms')->nullOnDelete();
            $table->date('date');
            $table->time('start_time')->nullable();
            $table->time('end_time')->nullable();
            $table->boolean('all_day')->default(false);
            $table->string('reason')->nullable();
            $table->timestamps();

            // Indexes
            $table->index('studio_id');
            $table->index('room_id');
            $table->index('date');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('blocked_schedules');
    }
};
