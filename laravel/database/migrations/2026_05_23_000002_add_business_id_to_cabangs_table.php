<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('cabangs', function (Blueprint $table) {
            if (!Schema::hasColumn('cabangs', 'business_id')) {
                $table->foreignId('business_id')->nullable()->after('modal_awal')->constrained('businesses')->nullOnDelete();
            }
        });
    }

    public function down(): void
    {
        Schema::table('cabangs', function (Blueprint $table) {
            if (Schema::hasColumn('cabangs', 'business_id')) {
                $table->dropForeign(['business_id']);
                $table->dropColumn('business_id');
            }
        });
    }
};
