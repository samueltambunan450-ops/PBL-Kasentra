<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Business;
use App\Models\Transaksi;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Throwable;

class TransaksiBesarController extends Controller
{
    /**
     * Get list of transaksi besar (above threshold) yang belum direview
     * Untuk Owner monitoring transaksi Kepala Cabang
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $user = $request->attributes->get('authUser');
            
            if (!$user || $user->role !== 'owner') {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized. Only owner can access this endpoint.',
                ], 403);
            }

            // Get business owned by this owner
            $business = Business::where('owner_id', $user->id)->first();
            
            if (!$business) {
                return response()->json([
                    'success' => true,
                    'message' => 'No business found',
                    'data' => [],
                ]);
            }

            // Check if threshold is set
            if (!$business->threshold_transaksi || $business->threshold_transaksi <= 0) {
                return response()->json([
                    'success' => true,
                    'message' => 'Threshold tidak diatur',
                    'data' => [],
                ]);
            }

            // Get cabang IDs for this business
            $cabangIds = $business->cabangs()->pluck('id');

            // Get transaksi above threshold from Kepala Cabang only
            $transaksis = Transaksi::with(['cabang', 'kategori', 'user'])
                ->whereIn('cabang_id', $cabangIds)
                ->where('nominal', '>', $business->threshold_transaksi)
                ->whereHas('user', function ($query) {
                    $query->where('role', 'kepala_cabang');
                })
                ->orderByDesc('tanggal')
                ->orderByDesc('id')
                ->get();

            return response()->json([
                'success' => true,
                'message' => 'Daftar transaksi besar',
                'data' => $transaksis,
                'threshold' => $business->threshold_transaksi,
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat transaksi besar',
                'errors' => ['exception' => $e->getMessage()],
            ], 500);
        }
    }

    /**
     * Get count of unreviewed transaksi besar
     * Untuk badge notifikasi di dashboard Owner
     */
    public function count(Request $request): JsonResponse
    {
        try {
            $user = $request->attributes->get('authUser');
            
            if (!$user || $user->role !== 'owner') {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized',
                ], 403);
            }

            $business = Business::where('owner_id', $user->id)->first();
            
            if (!$business || !$business->threshold_transaksi || $business->threshold_transaksi <= 0) {
                return response()->json([
                    'success' => true,
                    'count' => 0,
                ]);
            }

            $cabangIds = $business->cabangs()->pluck('id');

            $count = Transaksi::whereIn('cabang_id', $cabangIds)
                ->where('nominal', '>', $business->threshold_transaksi)
                ->where('is_reviewed', false)
                ->whereHas('user', function ($query) {
                    $query->where('role', 'kepala_cabang');
                })
                ->count();

            return response()->json([
                'success' => true,
                'count' => $count,
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal menghitung transaksi besar',
                'errors' => ['exception' => $e->getMessage()],
            ], 500);
        }
    }

    /**
     * Mark transaksi as reviewed
     */
    public function markAsReviewed(Request $request, $id): JsonResponse
    {
        try {
            $user = $request->attributes->get('authUser');
            
            if (!$user || $user->role !== 'owner') {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized',
                ], 403);
            }

            $transaksi = Transaksi::findOrFail($id);
            
            // Verify this transaksi belongs to owner's business
            $business = Business::where('owner_id', $user->id)->first();
            if (!$business) {
                return response()->json([
                    'success' => false,
                    'message' => 'Business not found',
                ], 404);
            }

            $cabangIds = $business->cabangs()->pluck('id');
            if (!$cabangIds->contains($transaksi->cabang_id)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized to review this transaction',
                ], 403);
            }

            $transaksi->update(['is_reviewed' => true]);

            return response()->json([
                'success' => true,
                'message' => 'Transaksi berhasil ditandai sebagai sudah ditinjau',
                'data' => $transaksi,
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal menandai transaksi',
                'errors' => ['exception' => $e->getMessage()],
            ], 500);
        }
    }
}
