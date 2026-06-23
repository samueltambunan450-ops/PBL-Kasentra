<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Database drift fix:
 * Tabel `invitations` di database production punya kolom `email` NOT NULL
 * yang tidak ada di migration asal. Migration ini menghapusnya agar INSERT
 * tidak gagal dengan "Field 'email' doesn't have a default value".
 */
return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasColumn('invitations', 'email')) {
            Schema::table('invitations', function (Blueprint $table) {
                $table->dropColumn('email');
            });
        }
    }

    public function down(): void
    {
        if (!Schema::hasColumn('invitations', 'email')) {
            Schema::table('invitations', function (Blueprint $table) {
                $table->string('email')->nullable()->after('code');
            });
        }
    }
};
