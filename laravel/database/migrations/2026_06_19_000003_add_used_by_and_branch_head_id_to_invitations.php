<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('invitations', function (Blueprint $table) {
            if (!Schema::hasColumn('invitations', 'branch_head_id')) {
                $table->foreignId('branch_head_id')
                    ->nullable()
                    ->after('cabang_id')
                    ->constrained('branch_heads')
                    ->nullOnDelete();
            }
            if (!Schema::hasColumn('invitations', 'used_by')) {
                $table->foreignId('used_by')
                    ->nullable()
                    ->after('branch_head_id')
                    ->constrained('users')
                    ->nullOnDelete();
            }
        });
    }

    public function down(): void
    {
        Schema::table('invitations', function (Blueprint $table) {
            if (Schema::hasColumn('invitations', 'branch_head_id')) {
                $table->dropForeign(['branch_head_id']);
                $table->dropColumn('branch_head_id');
            }
            if (Schema::hasColumn('invitations', 'used_by')) {
                $table->dropForeign(['used_by']);
                $table->dropColumn('used_by');
            }
        });
    }
};
