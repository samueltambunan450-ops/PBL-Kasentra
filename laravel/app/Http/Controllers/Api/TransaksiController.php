<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Business;
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

            if ($user?->role === 'owner') {
                // Scope ke cabang-cabang milik business owner ini saja
                $cabangIds = \App\Models\Business::where('owner_id', $user->id)
                    ->first()
                    ?->cabangs()
                    ->pluck('id') ?? collect();

                $query->whereIn('cabang_id', $cabangIds);
            } elseif ($user?->role === 'karyawan' || $user?->role === 'kepala_cabang') {
                $query->where('cabang_id', $user->cabang_id);
            } else {
                // Role tidak dikenali — kembalikan kosong
                return response()->json([
                    'success' => true,
                    'message' => 'Daftar transaksi',
                    'data'    => [],
                ]);
            }

            // Jangan gunakan array kolom di get() karena akan prevent loading relasi
            // Relasi 'user' diperlukan untuk accessor 'created_by_name'
            $transaksis = $query->get();

            return response()->json([
                'success' => true,
                'message' => 'Daftar transaksi',
                'data'    => $transaksis,
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat data transaksi',
                'errors'  => ['exception' => $e->getMessage()],
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

            // Validasi pengeluaran-first untuk Karyawan dan Kepala Cabang
            if (($user->role === 'karyawan' || $user->role === 'kepala_cabang') && $payload['jenis'] === 'pemasukan') {
                $sudahAdaPengeluaran = Transaksi::where('cabang_id', $payload['cabang_id'])
                    ->where('jenis', 'pengeluaran')
                    ->whereDate('tanggal', now('Asia/Jakarta')->toDateString())
                    ->exists();

                if (! $sudahAdaPengeluaran) {
                    $roleName = $user->role === 'kepala_cabang' ? 'Kepala cabang' : 'Karyawan';
                    return response()->json([
                        'success' => false,
                        'message' => $roleName . ' wajib input pengeluaran terlebih dahulu sebelum mencatat pemasukan hari ini.',
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

            // Debug logging
            \Log::info('Transaksi Created', [
                'id' => $transaksi->id,
                'user_id' => $transaksi->user_id,
                'foto_bukti' => $transaksi->foto_bukti,
                'user_loaded' => $transaksi->relationLoaded('user'),
                'user_exists' => $transaksi->user !== null,
                'user_name' => $transaksi->user?->name,
                'created_by_name_accessor' => $transaksi->created_by_name,
            ]);

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

        // Validasi pengeluaran-first berlaku untuk Karyawan dan Kepala Cabang
        if ($user->role !== 'karyawan' && $user->role !== 'kepala_cabang') {
            // Owner tidak perlu validasi ini, langsung kembalikan true
            return response()->json([
                'success' => true,
                'sudah_ada_pengeluaran' => true,
            ]);
        }

        $ada = Transaksi::where('cabang_id', $user->cabang_id)
            ->where('jenis', 'pengeluaran')
            ->whereDate('tanggal', now('Asia/Jakarta')->toDateString())
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
        
        $saved = Storage::disk('public')->put($fileName, $imageData);
        
        // Debug logging
        \Log::info('Save Foto Bukti', [
            'filename' => $fileName,
            'saved' => $saved,
            'exists' => Storage::disk('public')->exists($fileName),
            'full_path' => Storage::disk('public')->path($fileName),
            'size' => strlen($imageData),
        ]);
        
        return $fileName;
    }

    private function deleteFotoBukti(?string $path): void
    {
        if ($path && Storage::disk('public')->exists($path)) {
            Storage::disk('public')->delete($path);
        }
    }

    /**
     * Proxy endpoint untuk serve foto bukti dengan CORS headers
     * Mengatasi CORS issue saat Flutter Web load gambar dari Laravel
     */
    public function showFoto(Request $request, string $filename): mixed
    {
        try {
            $path = 'bukti/' . $filename;
            
            if (!Storage::disk('public')->exists($path)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Foto tidak ditemukan',
                ], 404);
            }

            $file = Storage::disk('public')->get($path);
            $mimeType = Storage::disk('public')->mimeType($path);

            return response($file, 200)
                ->header('Content-Type', $mimeType)
                ->header('Access-Control-Allow-Origin', '*')
                ->header('Access-Control-Allow-Methods', 'GET, OPTIONS')
                ->header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat foto',
                'errors' => ['exception' => $e->getMessage()],
            ], 500);
        }
    }
}
