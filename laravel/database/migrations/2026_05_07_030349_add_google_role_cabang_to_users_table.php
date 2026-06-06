<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'google_uid')) {
                $table->string('google_uid')->unique()->nullable()->after('email');
            }
            if (!Schema::hasColumn('users', 'role')) {
                $table->enum('role', ['owner', 'karyawan'])->default('karyawan')->after('google_uid');
            }
            if (!Schema::hasColumn('users', 'cabang_id')) {
                $table->unsignedBigInteger('cabang_id')->nullable()->after('role');
            }
        });

        Schema::table('users', function (Blueprint $table) {
            $table->foreign('cabang_id')->references('id')->on('cabangs')->nullOnDelete();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropForeign(['cabang_id']);
            $table->dropColumn(['google_uid', 'role', 'cabang_id']);
        });
    }
};
