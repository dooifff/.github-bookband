<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('equipment', function (Blueprint $table) {
            $table->id();
            $table->foreignId('studio_id')->constrained('studios')->cascadeOnDelete();
            $table->foreignId('room_id')->nullable()->constrained('studio_rooms')->nullOnDelete();
            $table->string('name');
            $table->text('description')->nullable();
            $table->string('brand')->nullable();
            $table->string('model')->nullable();
            $table->string('image')->nullable();
            $table->boolean('is_included')->default(true);
            $table->decimal('additional_price', 12, 2)->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            // Indexes
            $table->index('studio_id');
            $table->index('room_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('equipment');
    }
};
