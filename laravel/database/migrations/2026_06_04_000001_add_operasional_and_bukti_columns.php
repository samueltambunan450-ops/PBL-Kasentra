<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('cabangs', function (Blueprint $table) {
            $table->time('jam_buka')->nullable()->after('modal_awal');
            $table->time('jam_tutup')->nullable()->after('jam_buka');
        });

        Schema::table('transaksis', function (Blueprint $table) {
            $table->string('foto_bukti')->nullable()->after('keterangan');
            $table->boolean('is_modal_kiriman')->default(false)->after('foto_bukti');
        });
    }

    public function down(): void
    {
        Schema::table('transaksis', function (Blueprint $table) {
            $table->dropColumn('foto_bukti');
            $table->dropColumn('is_modal_kiriman');
        });

        Schema::table('cabangs', function (Blueprint $table) {
            $table->dropColumn('jam_buka');
            $table->dropColumn('jam_tutup');
        });
    }
};
