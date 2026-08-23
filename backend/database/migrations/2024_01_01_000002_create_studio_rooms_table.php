<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('studio_rooms', function (Blueprint $table) {
            $table->id();
            $table->foreignId('studio_id')->constrained('studios')->cascadeOnDelete();
            $table->string('name');
            $table->text('description')->nullable();
            $table->unsignedInteger('capacity');
            $table->decimal('price_per_hour', 12, 2);
            $table->boolean('is_active')->default(true);
            $table->softDeletes();
            $table->timestamps();

            // Indexes
            $table->index('studio_id');
            $table->index('is_active');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('studio_rooms');
    }
};
