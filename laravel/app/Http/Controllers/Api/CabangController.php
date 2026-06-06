<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
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
    public function index(): JsonResponse
    {
        try {
            $cabangs = Cabang::orderBy('id')->get(['id', 'nama', 'alamat', 'modal_awal', 'jam_buka', 'jam_tutup']);
            return response()->json([
                'success' => true,
                'message' => 'Daftar cabang',
                'data' => $cabangs,
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat data cabang',
                'errors' => ['exception' => $e->getMessage()],
            ], 500);
        }
    }

    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'nama' => ['required'],
            'alamat' => ['required'],
            'modal_awal' => ['required', 'numeric', 'min:0'],
            'jam_buka' => ['nullable', 'date_format:H:i'],
            'jam_tutup' => ['nullable', 'date_format:H:i'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $payload = $validator->validated();
            $cabang = Cabang::create($payload);
            return response()->json([
                'success' => true,
                'message' => 'Data berhasil disimpan',
                'data' => $cabang,
            ], 201);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal menyimpan cabang',
                'errors' => ['exception' => $e->getMessage()],
            ], 500);
        }
    }

    public function update(Request $request, $id): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'nama' => ['required'],
            'alamat' => ['required'],
            'modal_awal' => ['required', 'numeric', 'min:0'],
            'jam_buka' => ['nullable', 'date_format:H:i'],
            'jam_tutup' => ['nullable', 'date_format:H:i'],
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
                'message' => 'Data berhasil diperbarui',
                'data' => $cabang,
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal memperbarui cabang',
                'errors' => ['exception' => $e->getMessage()],
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

    public function destroy($id): JsonResponse
    {
        try {
            $cabang = Cabang::findOrFail($id);

            DB::transaction(function () use ($cabang) {
                // hapus karyawan dan transaksi terkait
                User::where('cabang_id', $cabang->id)->delete();
                Transaksi::where('cabang_id', $cabang->id)->delete();
                $cabang->delete();
            });

            return response()->json([
                'success' => true,
                'message' => 'Cabang berhasil dihapus',
                'data' => null,
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal menghapus cabang',
                'errors' => ['exception' => $e->getMessage()],
            ], 500);
        }
    }
}
