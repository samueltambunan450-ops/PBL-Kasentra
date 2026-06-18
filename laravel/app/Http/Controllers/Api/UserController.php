<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Throwable;

class UserController extends Controller
{
    public function indexKepalaCabang(Request $request): JsonResponse
    {
        try {
            $user = $request->attributes->get('authUser');

            if (!$user || $user->role !== 'owner') {
                return response()->json([
                    'success' => false,
                    'message' => 'Hanya owner yang dapat melihat data ini',
                ], 403);
            }

            $kepalaCabangs = User::with('cabang')
                ->where('role', 'kepala_cabang')
                ->get()
                ->map(function ($u) {
                    return [
                        'id'         => (string) $u->id,
                        'name'       => $u->name,
                        'nama'       => $u->name,
                        'email'      => $u->email,
                        'google_uid' => $u->google_uid ?? '',
                        'role'       => $u->role,
                        'cabang_id'  => $u->cabang_id 
                                        ? (string) $u->cabang_id 
                                        : null,
                        'status'     => $u->status ?? 'aktif',
                        'cabang'     => $u->cabang ? [
                            'id'   => (string) $u->cabang->id,
                            'nama' => $u->cabang->nama,
                        ] : null,
                    ];
                });

            return response()->json([
                'success' => true,
                'message' => 'Daftar kepala cabang',
                'data'    => $kepalaCabangs,
            ]);

        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat data',
                'errors'  => ['exception' => $e->getMessage()],
            ], 500);
        }
    }

    public function destroy(Request $request, $id): JsonResponse
    {
        try {
            $user = $request->attributes->get('authUser');

            if (!$user || $user->role !== 'owner') {
                return response()->json([
                    'success' => false,
                    'message' => 'Hanya owner yang dapat menghapus kepala cabang',
                ], 403);
            }

            $target = User::find($id);

            if (!$target) {
                return response()->json([
                    'success' => false,
                    'message' => 'User tidak ditemukan',
                ], 404);
            }

            if ($target->role !== 'kepala_cabang') {
                return response()->json([
                    'success' => false,
                    'message' => 'User bukan kepala cabang',
                ], 422);
            }

            // Reset role ke pending, bukan hapus user
            $target->update([
                'role'      => 'pending',
                'cabang_id' => null,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Kepala cabang berhasil dihapus dari cabang',
            ]);

        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal menghapus kepala cabang',
                'errors'  => ['exception' => $e->getMessage()],
            ], 500);
        }
    }
}
