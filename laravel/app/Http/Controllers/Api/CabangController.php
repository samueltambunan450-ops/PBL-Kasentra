<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Business;
use App\Models\Cabang;
use App\Models\Transaksi;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;
use Throwable;

class CabangController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        try {
            $user = $request->attributes->get('authUser');

            // Scope ke cabang milik business owner yang login
            // Karyawan & kepala_cabang hanya lihat cabang mereka sendiri
            if ($user?->role === 'owner') {
                // Cari semua business milik owner ini, lalu ambil cabangnya
                $businessIds = \App\Models\Business::where('owner_id', $user->id)
                    ->pluck('id');

                $cabangs = Cabang::whereIn('business_id', $businessIds)
                    ->orderBy('id')
                    ->get(['id', 'nama', 'alamat', 'modal_awal', 'jam_buka', 'jam_tutup', 'business_id']);
            } elseif ($user?->role === 'karyawan' || $user?->role === 'kepala_cabang') {
                // Karyawan / kepala cabang hanya bisa lihat cabangnya sendiri
                $cabangs = $user->cabang_id
                    ? Cabang::where('id', $user->cabang_id)
                        ->get(['id', 'nama', 'alamat', 'modal_awal', 'jam_buka', 'jam_tutup', 'business_id'])
                    : collect();
            } else {
                $cabangs = collect();
            }

            return response()->json([
                'success' => true,
                'message' => 'Daftar cabang',
                'data'    => $cabangs,
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat data cabang',
                'errors'  => ['exception' => $e->getMessage()],
            ], 500);
        }
    }

    public function store(Request $request): JsonResponse
    {
        $user = $request->attributes->get('authUser');
        if (!$user || $user->role !== 'owner') {
            return response()->json(['success' => false, 'message' => 'Hanya owner yang dapat menambah cabang'], 403);
        }

        $validator = Validator::make($request->all(), [
            'nama'      => ['required'],
            'alamat'    => ['required'],
            'modal_awal'=> ['required', 'numeric', 'min:0'],
            'jam_buka'  => ['nullable', 'date_format:H:i'],
            'jam_tutup' => ['nullable', 'date_format:H:i'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal',
                'errors'  => $validator->errors(),
            ], 422);
        }

        try {
            // Ambil business milik owner yang login — WAJIB scope ke tenant
            $business = Business::where('owner_id', $user->id)->first();
            if (!$business) {
                return response()->json([
                    'success' => false,
                    'message' => 'Belum ada usaha terdaftar untuk akun ini',
                ], 422);
            }

            $payload = array_merge($validator->validated(), [
                'business_id' => $business->id,
            ]);
            $cabang = Cabang::create($payload);

            return response()->json([
                'success' => true,
                'message' => 'Data berhasil disimpan',
                'data'    => $cabang,
            ], 201);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal menyimpan cabang',
                'errors'  => ['exception' => $e->getMessage()],
            ], 500);
        }
    }

    public function update(Request $request, $id): JsonResponse
    {
        $user = $request->attributes->get('authUser');
        if (!$user || $user->role !== 'owner') {
            return response()->json(['success' => false, 'message' => 'Hanya owner yang dapat mengubah cabang'], 403);
        }

        $validator = Validator::make($request->all(), [
            'nama'      => ['required'],
            'alamat'    => ['required'],
            'modal_awal'=> ['required', 'numeric', 'min:0'],
            'jam_buka'  => ['nullable', 'date_format:H:i'],
            'jam_tutup' => ['nullable', 'date_format:H:i'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal',
                'errors'  => $validator->errors(),
            ], 422);
        }

        try {
            $cabang = Cabang::findOrFail($id);

            // Pastikan cabang ini benar-benar milik business owner yang login
            $ownsIt = Business::where('owner_id', $user->id)
                ->where('id', $cabang->business_id)
                ->exists();
            // Izinkan juga cabang legacy (business_id null) untuk owner
            if ($cabang->business_id !== null && !$ownsIt) {
                return response()->json(['success' => false, 'message' => 'Cabang tidak dimiliki oleh usaha Anda'], 403);
            }

            $cabang->update($validator->validated());
            return response()->json([
                'success' => true,
                'message' => 'Data berhasil diperbarui',
                'data'    => $cabang,
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal memperbarui cabang',
                'errors'  => ['exception' => $e->getMessage()],
            ], 500);
        }
    }

    public function updateJamOperasional(Request $request, $id): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'jam_buka' => ['required', 'date_format:H:i'],
            'jam_tutup' => ['required', 'date_format:H:i'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $cabang = Cabang::findOrFail($id);
            $cabang->update($validator->validated());
            return response()->json([
                'success' => true,
                'message' => 'Jam operasional berhasil diperbarui',
                'data' => $cabang,
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal memperbarui jam operasional',
                'errors' => ['exception' => $e->getMessage()],
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
                    'message' => 'Hanya owner yang dapat menghapus cabang'
                ], 403);
            }

            $cabang = Cabang::findOrFail($id);

            // Pastikan cabang ini milik business owner yang login
            $ownsIt = Business::where('owner_id', $user->id)
                ->where('id', $cabang->business_id)
                ->exists();
            // Allow legacy cabangs (business_id null) for owner
            if ($cabang->business_id !== null && !$ownsIt) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cabang tidak dimiliki oleh usaha Anda'
                ], 403);
            }

            // Check if cabang has any transaksi
            $hasTransaksi = Transaksi::where('cabang_id', $cabang->id)->exists();
            if ($hasTransaksi) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cabang tidak dapat dihapus karena masih memiliki data transaksi'
                ], 422);
            }

            // Check if cabang has active Kepala Cabang
            $hasKepalaCabang = User::where('cabang_id', $cabang->id)
                ->where('role', 'kepala_cabang')
                ->exists();
            if ($hasKepalaCabang) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cabang tidak dapat dihapus karena masih memiliki Kepala Cabang aktif'
                ], 422);
            }

            // Check if cabang has any karyawan
            $hasKaryawan = User::where('cabang_id', $cabang->id)
                ->where('role', 'karyawan')
                ->exists();
            if ($hasKaryawan) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cabang tidak dapat dihapus karena masih memiliki karyawan aktif'
                ], 422);
            }

            // Safe to delete
            $cabang->delete();

            return response()->json([
                'success' => true,
                'message' => 'Cabang berhasil dihapus',
                'data'    => null,
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal menghapus cabang',
                'errors'  => ['exception' => $e->getMessage()],
            ], 500);
        }
    }
}
