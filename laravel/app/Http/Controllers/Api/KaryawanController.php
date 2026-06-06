<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;
use Throwable;

class KaryawanController extends Controller
{
    public function index(): JsonResponse
    {
        try {
            $karyawans = User::where('role', 'karyawan')
                ->orderBy('id')
                ->get(['id', 'name', 'email', 'google_uid', 'role', 'cabang_id']);

            return response()->json([
                'success' => true,
                'message' => 'Daftar karyawan',
                'data' => $karyawans,
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat data karyawan',
                'errors' => ['exception' => $e->getMessage()],
            ], 500);
        }
    }

    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'cabang_id' => ['nullable', 'exists:cabangs,id'],
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
            $user = User::create(array_merge($data, ['role' => 'karyawan']));
            return response()->json([
                'success' => true,
                'message' => 'Data berhasil disimpan',
                'data' => $user,
            ], 201);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal menyimpan karyawan',
                'errors' => ['exception' => $e->getMessage()],
            ], 500);
        }
    }

    public function update(Request $request, $id): JsonResponse
    {
        $user = User::findOrFail($id);
        $validator = Validator::make($request->all(), [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', Rule::unique('users', 'email')->ignore($user->id)],
            'cabang_id' => ['nullable', 'exists:cabangs,id'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $user->update($validator->validated());
            return response()->json([
                'success' => true,
                'message' => 'Data berhasil diperbarui',
                'data' => $user,
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal memperbarui karyawan',
                'errors' => ['exception' => $e->getMessage()],
            ], 500);
        }
    }

    public function destroy($id): JsonResponse
    {
        try {
            $user = User::findOrFail($id);
            if ($user->role === 'owner') {
                return response()->json([
                    'success' => false,
                    'message' => 'Tidak dapat menghapus user dengan role owner',
                    'errors' => null,
                ], 403);
            }
            $user->delete();
            return response()->json([
                'success' => true,
                'message' => 'Karyawan berhasil dihapus',
                'data' => null,
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal menghapus karyawan',
                'errors' => ['exception' => $e->getMessage()],
            ], 500);
        }
    }
}
