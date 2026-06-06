<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Cabang;
use App\Models\Transaksi;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Throwable;

class TransaksiController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        try {
            $user = $request->attributes->get('authUser');
            $query = Transaksi::with(['cabang', 'kategori', 'user'])
                ->orderByDesc('tanggal')
                ->orderByDesc('id');

            if ($user?->role === 'karyawan') {
                $query->where('cabang_id', $user->cabang_id);
            }

            $transaksis = $query->get([
                'id', 'cabang_id', 'kategori_id', 'user_id', 'jenis', 'nominal', 'tanggal', 'keterangan', 'foto_bukti', 'is_modal_kiriman',
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Daftar transaksi',
                'data' => $transaksis,
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat data transaksi',
                'errors' => ['exception' => $e->getMessage()],
            ], 500);
        }
    }

    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'cabang_id' => ['required', 'integer', 'exists:cabangs,id'],
            'kategori_id' => ['nullable', 'integer', 'exists:kategoris,id'],
            'jenis' => ['required', 'in:pemasukan,pengeluaran'],
            'nominal' => ['required', 'integer', 'min:1'],
            'tanggal' => ['required', 'date'],
            'keterangan' => ['required', 'string'],
            'foto_bukti' => ['nullable', 'string'],
            'is_modal_kiriman' => ['nullable', 'boolean'],
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
            $user = $request->attributes->get('authUser');

            if (! $user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pengguna tidak terautentikasi.',
                ], 401);
            }

            $cabang = Cabang::findOrFail($payload['cabang_id']);

            if ($user->role === 'karyawan' && ! $cabang->isOpen()) {
                return response()->json([
                    'success' => false,
                    'message' => "Cabang sedang tutup. Jam operasional: {$cabang->jam_buka} - {$cabang->jam_tutup}",
                ], 403);
            }

            if ($user->role === 'karyawan' && $payload['jenis'] === 'pemasukan') {
                $sudahAdaPengeluaran = Transaksi::where('cabang_id', $payload['cabang_id'])
                    ->where('jenis', 'pengeluaran')
                    ->whereDate('tanggal', now()->toDateString())
                    ->exists();

                if (! $sudahAdaPengeluaran) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Karyawan wajib input pengeluaran terlebih dahulu sebelum mencatat pemasukan hari ini.',
                    ], 422);
                }
            }

            $fotoBuktiPath = null;
            if (! empty($payload['foto_bukti'])) {
                $fotoBuktiPath = $this->saveFotoBukti($payload['foto_bukti']);
            }

            $transaksi = Transaksi::create([
                'cabang_id' => $payload['cabang_id'],
                'kategori_id' => $payload['kategori_id'] ?? null,
                'user_id' => $user->id,
                'jenis' => $payload['jenis'],
                'nominal' => $payload['nominal'],
                'tanggal' => $payload['tanggal'],
                'keterangan' => $payload['keterangan'],
                'foto_bukti' => $fotoBuktiPath,
                'is_modal_kiriman' => $payload['is_modal_kiriman'] ?? false,
            ]);

            $transaksi->load(['cabang', 'kategori', 'user']);

            return response()->json([
                'success' => true,
                'message' => 'Data berhasil disimpan',
                'data' => $transaksi,
            ], 201);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal menyimpan transaksi',
                'errors' => ['exception' => $e->getMessage()],
            ], 500);
        }
    }

    public function update(Request $request, $id): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'cabang_id' => ['required', 'integer', 'exists:cabangs,id'],
            'kategori_id' => ['nullable', 'integer', 'exists:kategoris,id'],
            'jenis' => ['required', 'in:pemasukan,pengeluaran'],
            'nominal' => ['required', 'integer', 'min:1'],
            'tanggal' => ['required', 'date'],
            'keterangan' => ['required', 'string'],
            'foto_bukti' => ['nullable', 'string'],
            'is_modal_kiriman' => ['nullable', 'boolean'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $transaksi = Transaksi::findOrFail($id);
            $payload = $validator->validated();

            if (array_key_exists('foto_bukti', $payload) && ! empty($payload['foto_bukti'])) {
                if ($transaksi->foto_bukti) {
                    $this->deleteFotoBukti($transaksi->foto_bukti);
                }
                $payload['foto_bukti'] = $this->saveFotoBukti($payload['foto_bukti']);
            }

            $transaksi->update($payload);
            $transaksi->load(['cabang', 'kategori', 'user']);

            return response()->json([
                'success' => true,
                'message' => 'Data berhasil diperbarui',
                'data' => $transaksi,
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal memperbarui transaksi',
                'errors' => ['exception' => $e->getMessage()],
            ], 500);
        }
    }

    public function destroy($id): JsonResponse
    {
        try {
            $transaksi = Transaksi::find($id);
            if (! $transaksi) {
                return response()->json([
                    'success' => false,
                    'message' => 'Transaksi tidak ditemukan',
                    'errors' => null,
                ], 404);
            }

            if ($transaksi->foto_bukti) {
                $this->deleteFotoBukti($transaksi->foto_bukti);
            }

            $transaksi->delete();
            return response()->json([
                'success' => true,
                'message' => 'Transaksi berhasil dihapus',
                'data' => null,
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal menghapus transaksi',
                'errors' => ['exception' => $e->getMessage()],
            ], 500);
        }
    }

    public function cekPengeluaranHariIni(Request $request): JsonResponse
    {
        $user = $request->attributes->get('authUser');
        if (! $user || ! $user->cabang_id) {
            return response()->json([
                'success' => false,
                'message' => 'Pengguna tidak terautentikasi atau tidak terhubung dengan cabang.',
            ], 401);
        }

        $ada = Transaksi::where('cabang_id', $user->cabang_id)
            ->where('jenis', 'pengeluaran')
            ->whereDate('tanggal', now()->toDateString())
            ->exists();

        return response()->json([
            'success' => true,
            'sudah_ada_pengeluaran' => $ada,
        ]);
    }

    private function saveFotoBukti(string $base64): string
    {
        $imageData = preg_replace('/^data:image\/\w+;base64,/', '', $base64);
        $imageData = base64_decode($imageData);
        $fileName = 'bukti/' . uniqid() . '.jpg';
        Storage::disk('public')->put($fileName, $imageData);
        return $fileName;
    }

    private function deleteFotoBukti(?string $path): void
    {
        if ($path && Storage::disk('public')->exists($path)) {
            Storage::disk('public')->delete($path);
        }
    }
}
