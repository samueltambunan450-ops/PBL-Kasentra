<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     * 
     * Fix transaksi lama yang user_id-nya NULL dengan assign ke Owner bisnis terkait
     * NOTE: Kolom di database adalah 'user_id' (bukan 'created_by')
     */
    public function up(): void
    {
        // 1. Hitung jumlah transaksi dengan user_id NULL sebelum update
        $nullCount = DB::table('transaksis')
            ->whereNull('user_id')
            ->count();
        
        echo "\n========================================\n";
        echo "DATA FIX: Transaksi dengan user_id NULL\n";
        echo "========================================\n";
        echo "Jumlah transaksi yang perlu di-fix: {$nullCount}\n\n";

        if ($nullCount === 0) {
            echo "✅ Tidak ada transaksi yang perlu di-fix.\n";
            echo "========================================\n";
            return;
        }

        // 2. Ambil semua transaksi yang user_id-nya NULL
        $transaksis = DB::table('transaksis')
            ->whereNull('user_id')
            ->get(['id', 'cabang_id']);

        $updated = 0;
        $skipped = 0;
        $fallbackOwner = null;

        foreach ($transaksis as $transaksi) {
            try {
                // Ambil cabang_id dari transaksi
                $cabangId = $transaksi->cabang_id;

                if (!$cabangId) {
                    // Edge case: cabang_id NULL
                    echo "⚠️  Transaksi ID {$transaksi->id}: cabang_id NULL\n";
                    
                    // Fallback: ambil owner pertama (business_id terkecil)
                    if (!$fallbackOwner) {
                        $fallbackOwner = DB::table('businesses')
                            ->orderBy('id', 'asc')
                            ->value('owner_id');
                    }
                    
                    if ($fallbackOwner) {
                        DB::table('transaksis')
                            ->where('id', $transaksi->id)
                            ->update(['user_id' => $fallbackOwner]);
                        $updated++;
                        echo "   → Fallback ke owner ID {$fallbackOwner}\n";
                    } else {
                        echo "   → Skip (tidak ada business di database)\n";
                        $skipped++;
                    }
                    continue;
                }

                // Ambil business_id dari cabang
                $businessId = DB::table('cabangs')
                    ->where('id', $cabangId)
                    ->value('business_id');

                if (!$businessId) {
                    // Edge case: business tidak ditemukan
                    echo "⚠️  Transaksi ID {$transaksi->id}: business untuk cabang {$cabangId} tidak ditemukan\n";
                    
                    // Fallback: ambil owner pertama
                    if (!$fallbackOwner) {
                        $fallbackOwner = DB::table('businesses')
                            ->orderBy('id', 'asc')
                            ->value('owner_id');
                    }
                    
                    if ($fallbackOwner) {
                        DB::table('transaksis')
                            ->where('id', $transaksi->id)
                            ->update(['user_id' => $fallbackOwner]);
                        $updated++;
                        echo "   → Fallback ke owner ID {$fallbackOwner}\n";
                    } else {
                        echo "   → Skip (tidak ada business di database)\n";
                        $skipped++;
                    }
                    continue;
                }

                // Ambil owner_id dari business
                $ownerId = DB::table('businesses')
                    ->where('id', $businessId)
                    ->value('owner_id');

                if (!$ownerId) {
                    // Edge case: owner tidak ditemukan
                    echo "⚠️  Transaksi ID {$transaksi->id}: owner untuk business {$businessId} tidak ditemukan\n";
                    $skipped++;
                    continue;
                }

                // Update user_id dengan owner_id
                DB::table('transaksis')
                    ->where('id', $transaksi->id)
                    ->update(['user_id' => $ownerId]);
                
                $updated++;

            } catch (\Exception $e) {
                echo "❌ Error pada transaksi ID {$transaksi->id}: {$e->getMessage()}\n";
                $skipped++;
            }
        }

        // 3. Verifikasi hasil
        $remainingNull = DB::table('transaksis')
            ->whereNull('user_id')
            ->count();

        echo "\n========================================\n";
        echo "HASIL MIGRATION:\n";
        echo "========================================\n";
        echo "✅ Transaksi ter-update: {$updated}\n";
        echo "⚠️  Transaksi di-skip: {$skipped}\n";
        echo "📊 Sisa user_id NULL: {$remainingNull}\n";
        
        // Spot check: ambil 3 transaksi sample untuk verifikasi
        echo "\n========================================\n";
        echo "SPOT CHECK (3 transaksi sample):\n";
        echo "========================================\n";
        
        $samples = DB::table('transaksis')
            ->join('users', 'transaksis.user_id', '=', 'users.id')
            ->join('cabangs', 'transaksis.cabang_id', '=', 'cabangs.id')
            ->join('businesses', 'cabangs.business_id', '=', 'businesses.id')
            ->select(
                'transaksis.id as transaksi_id',
                'transaksis.keterangan',
                'users.name as creator_name',
                'users.id as creator_id',
                'businesses.owner_id'
            )
            ->whereIn('transaksis.id', function($query) {
                $query->select('id')
                    ->from('transaksis')
                    ->whereNotNull('user_id')
                    ->orderBy('id', 'asc')
                    ->limit(3);
            })
            ->get();

        foreach ($samples as $sample) {
            $isOwner = $sample->creator_id == $sample->owner_id ? '✅ OWNER' : '❓ BUKAN OWNER';
            echo "Transaksi #{$sample->transaksi_id}: {$sample->keterangan}\n";
            echo "  Created by: {$sample->creator_name} (ID: {$sample->creator_id}) {$isOwner}\n";
            echo "  Owner ID: {$sample->owner_id}\n\n";
        }
        
        echo "========================================\n";
    }

    /**
     * Reverse the migrations.
     * 
     * Rollback tidak perlu set kembali ke NULL karena data sudah benar
     */
    public function down(): void
    {
        // Rollback: tidak perlu set kembali ke NULL
        // Data yang sudah di-fix tetap di-maintain
        echo "\n========================================\n";
        echo "ROLLBACK: Fix user_id NULL\n";
        echo "========================================\n";
        echo "⚠️  Rollback tidak mengubah data.\n";
        echo "Data user_id yang sudah di-fix tetap di-maintain.\n";
        echo "========================================\n";
    }
};
