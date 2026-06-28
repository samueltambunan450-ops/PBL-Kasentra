<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Business;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Throwable;

class BusinessController extends Controller
{
    /**
     * Update threshold transaksi for business
     * Only owner can update their own business threshold
     */
    public function updateThreshold(Request $request, $id): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'threshold_transaksi' => ['nullable', 'integer', 'min:0'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $user = $request->attributes->get('authUser');
            
            if (!$user || $user->role !== 'owner') {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized. Only owner can update threshold.',
                ], 403);
            }

            $business = Business::findOrFail($id);
            
            // Verify this business belongs to the authenticated owner
            if ($business->owner_id !== $user->id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized to update this business',
                ], 403);
            }

            $business->update([
                'threshold_transaksi' => $request->input('threshold_transaksi'),
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Threshold berhasil diperbarui',
                'data' => $business,
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal memperbarui threshold',
                'errors' => ['exception' => $e->getMessage()],
            ], 500);
        }
    }

    /**
     * Get business info including threshold
     */
    public function show(Request $request, $id): JsonResponse
    {
        try {
            $user = $request->attributes->get('authUser');
            
            if (!$user || $user->role !== 'owner') {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized',
                ], 403);
            }

            $business = Business::findOrFail($id);
            
            // Verify ownership
            if ($business->owner_id !== $user->id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized',
                ], 403);
            }

            return response()->json([
                'success' => true,
                'data' => $business,
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat data business',
                'errors' => ['exception' => $e->getMessage()],
            ], 500);
        }
    }
}
