<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('studios', function (Blueprint $table) {
            $table->string('subscription_status')->default('none')->after('is_active');
            $table->timestamp('subscription_expires_at')->nullable()->after('subscription_status');
            $table->unsignedTinyInteger('subscription_warning_level')->default(0)->after('subscription_expires_at');
            $table->timestamp('subscription_last_warning_at')->nullable()->after('subscription_warning_level');

            $table->index('subscription_status');
            $table->index('subscription_expires_at');
        });
    }

    public function down(): void
    {
        Schema::table('studios', function (Blueprint $table) {
            $table->dropIndex(['subscription_status']);
            $table->dropIndex(['subscription_expires_at']);
            $table->dropColumn([
                'subscription_status',
                'subscription_expires_at',
                'subscription_warning_level',
                'subscription_last_warning_at',
            ]);
        });
    }
};
