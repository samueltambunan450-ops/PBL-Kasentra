<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Kategori;
use App\Http\Resources\KategoriResource;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;
use Throwable;

class KategoriController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        try {
            $user = $request->attributes->get('authUser');
            $query = Kategori::with('cabang')->orderBy('id');
            
            if ($user?->role === 'karyawan') {
                $query->where(function ($q) use ($user) {
                    $q->where('scope', 'global')
                        ->orWhere(function ($q2) use ($user) {
                            $q2->where('scope', 'cabang')
                                ->where('cabang_id', $user->cabang_id);
                        });
                });
            }

            $kategoris = $query->get();
            return response()->json([
                'success' => true,
                'message' => 'Daftar kategori',
                'data' => KategoriResource::collection($kategoris),
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat data kategori',
                'errors' => ['exception' => $e->getMessage()],
            ], 500);
        }
    }

    public function store(Request $request): JsonResponse
    {
        $user = $request->attributes->get('authUser');
        
        // Authorization check: Only Owner can create
        if ($user?->role !== 'owner') {
            return response()->json([
                'success' => false,
                'message' => 'Akses ditolak. Hanya Owner yang dapat menambah kategori.',
            ], 403);
        }

        $validator = Validator::make($request->all(), [
            'nama' => ['required', 'string'],
            'jenis' => ['required', 'in:pemasukan,pengeluaran'],
            'scope' => ['required', 'in:global,cabang'],
            'cabang_id' => [
                'nullable',
                'exists:cabangs,id',
                'required_if:scope,cabang',
            ],
        ], [
            'nama.required' => 'Nama kategori wajib diisi',
            'cabang_id.required_if' => 'Pilih cabang terlebih dahulu',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $data = $validator->validated();
            
            // If scope is global, cabang_id MUST be null
            if ($data['scope'] === 'global') {
                $data['cabang_id'] = null;
            }

            $kategori = Kategori::create($data);
            $kategori->load('cabang');

            return response()->json([
                'success' => true,
                'message' => 'Data berhasil disimpan',
                'data' => new KategoriResource($kategori),
            ], 201);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal menyimpan kategori',
                'errors' => ['exception' => $e->getMessage()],
            ], 500);
        }
    }

    public function update(Request $request, $id): JsonResponse
    {
        $user = $request->attributes->get('authUser');
        
        // Authorization check: Only Owner can update
        if ($user?->role !== 'owner') {
            return response()->json([
                'success' => false,
                'message' => 'Akses ditolak. Hanya Owner yang dapat memperbarui kategori.',
            ], 403);
        }

        $validator = Validator::make($request->all(), [
            'nama' => ['required', 'string'],
            'jenis' => ['required', 'in:pemasukan,pengeluaran'],
            'scope' => ['required', 'in:global,cabang'],
            'cabang_id' => [
                'nullable',
                'exists:cabangs,id',
                'required_if:scope,cabang',
            ],
        ], [
            'nama.required' => 'Nama kategori wajib diisi',
            'cabang_id.required_if' => 'Pilih cabang terlebih dahulu',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $kategori = Kategori::findOrFail($id);
            $data = $validator->validated();

            // If scope is global, cabang_id MUST be null
            if ($data['scope'] === 'global') {
                $data['cabang_id'] = null;
            }

            $kategori->update($data);
            $kategori->load('cabang');

            return response()->json([
                'success' => true,
                'message' => 'Data berhasil diperbarui',
                'data' => new KategoriResource($kategori),
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal memperbarui kategori',
                'errors' => ['exception' => $e->getMessage()],
            ], 500);
        }
    }

    public function destroy(Request $request, $id): JsonResponse
    {
        $user = $request->attributes->get('authUser');
        
        // Authorization check: Only Owner can delete
        if ($user?->role !== 'owner') {
            return response()->json([
                'success' => false,
                'message' => 'Akses ditolak. Hanya Owner yang dapat menghapus kategori.',
            ], 403);
        }

        try {
            $kategori = Kategori::findOrFail($id);
            $kategori->delete();
            return response()->json([
                'success' => true,
                'message' => 'Kategori berhasil dihapus',
                'data' => null,
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal menghapus kategori',
                'errors' => ['exception' => $e->getMessage()],
            ], 500);
        }
    }
}
