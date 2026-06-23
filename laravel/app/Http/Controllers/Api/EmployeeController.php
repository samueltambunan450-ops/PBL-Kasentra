<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\EmployeeResource;
use App\Models\BranchHead;
use App\Models\Business;
use App\Models\Cabang;
use App\Models\Employee;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Throwable;

class EmployeeController extends Controller
{
    /**
     * GET /api/branches/{id}/employees
     * List karyawan di cabang — bisa diakses owner (cabangnya) atau kepala cabang (cabangnya).
     */
    public function index(Request $request, int $branchId): JsonResponse
    {
        $user = $request->attributes->get('authUser');
        if (!$user) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        try {
            $cabang = Cabang::find($branchId);
            if (!$cabang) {
                return response()->json(['message' => 'Cabang tidak ditemukan'], 404);
            }

            if ($user->isOwner()) {
                // Owner: pastikan cabang ini benar-benar milik businessnya
                $owned = Business::where('owner_id', $user->id)
                    ->whereHas('cabangs', fn($q) => $q->where('id', $branchId))
                    ->exists();
                // Izinkan juga legacy (business_id null)
                if ($cabang->business_id !== null && !$owned) {
                    return response()->json(['message' => 'Cabang tidak milik usaha Anda'], 403);
                }
            } elseif ($user->isKepalaCabang()) {
                $branchHead = BranchHead::where('branch_id', $branchId)
                    ->where('user_id', $user->id)
                    ->first();
                if (!$branchHead) {
                    return response()->json(['message' => 'Anda bukan kepala cabang untuk cabang ini'], 403);
                }
            } else {
                return response()->json(['message' => 'Akses ditolak'], 403);
            }

            $employees = Employee::where('branch_id', $branchId)
                ->with('branch')
                ->orderBy('nama')
                ->get();

            return response()->json([
                'success' => true,
                'message' => 'Daftar karyawan',
                'data'    => EmployeeResource::collection($employees),
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat karyawan',
                'errors'  => ['exception' => $e->getMessage()],
            ], 500);
        }
    }

    /**
     * POST /api/branches/{id}/employees
     * Tambah karyawan — hanya kepala cabang. Status otomatis "pending" (butuh approval owner).
     */
    public function store(Request $request, int $branchId): JsonResponse
    {
        $user = $request->attributes->get('authUser');
        if (!$user || !$user->isKepalaCabang()) {
            return response()->json(['message' => 'Hanya kepala cabang yang dapat menambahkan karyawan'], 403);
        }

        $branchHead = BranchHead::where('branch_id', $branchId)
            ->where('user_id', $user->id)
            ->where('is_active', true)
            ->first();

        if (!$branchHead) {
            return response()->json(['message' => 'Anda bukan kepala cabang aktif untuk cabang ini'], 403);
        }

        $data = $request->validate([
            'nama'       => ['required', 'string', 'max:255'],
            'jabatan'    => ['required', 'string', 'max:255'],
            'gaji_pokok' => ['required', 'numeric', 'min:0'],
        ]);

        try {
            $employee = Employee::create(array_merge($data, [
                'branch_id'      => $branchId,
                'branch_head_id' => $branchHead->id,
                'status'         => 'pending', // butuh approval owner
            ]));

            return response()->json([
                'success' => true,
                'message' => 'Karyawan berhasil ditambahkan, menunggu persetujuan pemilik usaha',
                'data'    => new EmployeeResource($employee),
            ], 201);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal menambahkan karyawan',
                'errors'  => ['exception' => $e->getMessage()],
            ], 500);
        }
    }

    /**
     * PUT /api/employees/{id}
     * Edit data karyawan — kepala cabang yang bersangkutan saja.
     * Edit tidak mengubah status (sudah approved tetap approved).
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $user = $request->attributes->get('authUser');
        if (!$user || !$user->isKepalaCabang()) {
            return response()->json(['message' => 'Hanya kepala cabang yang dapat mengedit karyawan'], 403);
        }

        $employee = Employee::find($id);
        if (!$employee) {
            return response()->json(['message' => 'Karyawan tidak ditemukan'], 404);
        }

        $branchHead = BranchHead::where('branch_id', $employee->branch_id)
            ->where('user_id', $user->id)
            ->first();

        if (!$branchHead) {
            return response()->json(['message' => 'Anda tidak berwenang mengedit karyawan ini'], 403);
        }

        $data = $request->validate([
            'nama'       => ['required', 'string', 'max:255'],
            'jabatan'    => ['required', 'string', 'max:255'],
            'gaji_pokok' => ['required', 'numeric', 'min:0'],
        ]);

        try {
            $employee->update($data);

            return response()->json([
                'success' => true,
                'message' => 'Data karyawan berhasil diperbarui',
                'data'    => new EmployeeResource($employee->fresh()),
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal memperbarui karyawan',
                'errors'  => ['exception' => $e->getMessage()],
            ], 500);
        }
    }

    /**
     * DELETE /api/employees/{id}
     * Hapus karyawan — kepala cabang atau owner.
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $user = $request->attributes->get('authUser');

        $employee = Employee::find($id);
        if (!$employee) {
            return response()->json(['message' => 'Karyawan tidak ditemukan'], 404);
        }

        if ($user->isKepalaCabang()) {
            $branchHead = BranchHead::where('branch_id', $employee->branch_id)
                ->where('user_id', $user->id)
                ->first();
            if (!$branchHead) {
                return response()->json(['message' => 'Anda tidak berwenang menghapus karyawan ini'], 403);
            }
        } elseif ($user->isOwner()) {
            $owned = Business::where('owner_id', $user->id)
                ->whereHas('cabangs', fn($q) => $q->where('id', $employee->branch_id))
                ->exists();
            if (!$owned) {
                return response()->json(['message' => 'Karyawan tidak milik usaha Anda'], 403);
            }
        } else {
            return response()->json(['message' => 'Akses ditolak'], 403);
        }

        try {
            $employee->delete();
            return response()->json([
                'success' => true,
                'message' => 'Karyawan berhasil dihapus',
                'data'    => null,
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal menghapus karyawan',
                'errors'  => ['exception' => $e->getMessage()],
            ], 500);
        }
    }

    /**
     * PATCH /api/employees/{id}/approve
     * Owner menyetujui karyawan pending.
     */
    public function approve(Request $request, int $id): JsonResponse
    {
        return $this->changeStatus($request, $id, 'approved', 'disetujui');
    }

    /**
     * PATCH /api/employees/{id}/reject
     * Owner menolak karyawan pending.
     */
    public function reject(Request $request, int $id): JsonResponse
    {
        return $this->changeStatus($request, $id, 'rejected', 'ditolak');
    }

    /**
     * GET /api/businesses/{businessId}/employees/pending
     * Owner melihat semua karyawan pending di seluruh cabang bisnisnya.
     */
    public function pendingByBusiness(Request $request, int $businessId): JsonResponse
    {
        $user = $request->attributes->get('authUser');
        if (!$user || !$user->isOwner()) {
            return response()->json(['message' => 'Hanya owner yang dapat melihat karyawan pending'], 403);
        }

        $business = Business::where('id', $businessId)
            ->where('owner_id', $user->id)
            ->first();
        if (!$business) {
            return response()->json(['message' => 'Usaha tidak ditemukan'], 404);
        }

        try {
            // Ambil semua cabang milik bisnis ini
            $cabangIds = $business->cabangs()->pluck('id');

            $employees = Employee::whereIn('branch_id', $cabangIds)
                ->where('status', 'pending')
                ->with('branch')
                ->orderBy('created_at', 'desc')
                ->get();

            return response()->json([
                'success' => true,
                'message' => 'Karyawan menunggu persetujuan',
                'data'    => EmployeeResource::collection($employees),
                'total'   => $employees->count(),
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat data',
                'errors'  => ['exception' => $e->getMessage()],
            ], 500);
        }
    }

    /**
     * GET /api/businesses/{businessId}/employees/pending/count
     * Hitung jumlah karyawan pending — untuk badge di dashboard owner.
     */
    public function pendingCount(Request $request, int $businessId): JsonResponse
    {
        $user = $request->attributes->get('authUser');
        if (!$user || !$user->isOwner()) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $business = Business::where('id', $businessId)
            ->where('owner_id', $user->id)
            ->first();
        if (!$business) {
            return response()->json(['count' => 0]);
        }

        try {
            $cabangIds = $business->cabangs()->pluck('id');
            $count = Employee::whereIn('branch_id', $cabangIds)
                ->where('status', 'pending')
                ->count();

            return response()->json(['success' => true, 'count' => $count]);
        } catch (Throwable $e) {
            return response()->json(['success' => false, 'count' => 0]);
        }
    }

    /**
     * GET /api/branches/{branchId}/employees/total-salary
     * Hitung total gaji karyawan approved di cabang ini — untuk auto-fill pengeluaran gaji.
     */
    public function totalSalary(Request $request, int $branchId): JsonResponse
    {
        $user = $request->attributes->get('authUser');
        if (!$user || !$user->isOwner()) {
            return response()->json(['message' => 'Hanya owner yang dapat mengakses endpoint ini'], 403);
        }

        $cabang = Cabang::find($branchId);
        if (!$cabang) {
            return response()->json(['message' => 'Cabang tidak ditemukan'], 404);
        }

        // Pastikan cabang ini milik owner yang login
        $owned = Business::where('owner_id', $user->id)
            ->whereHas('cabangs', fn($q) => $q->where('id', $branchId))
            ->exists();
        if (!$owned) {
            return response()->json(['message' => 'Cabang tidak milik usaha Anda'], 403);
        }

        try {
            // Hitung total gaji karyawan yang statusnya 'approved'
            $totalGaji = Employee::where('branch_id', $branchId)
                ->where('status', 'approved')
                ->sum('gaji_pokok');

            $jumlahKaryawan = Employee::where('branch_id', $branchId)
                ->where('status', 'approved')
                ->count();

            return response()->json([
                'success'          => true,
                'total_gaji'       => (float) $totalGaji,
                'jumlah_karyawan'  => $jumlahKaryawan,
                'cabang_nama'      => $cabang->nama,
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal menghitung total gaji',
                'errors'  => ['exception' => $e->getMessage()],
            ], 500);
        }
    }

    // ── Private helper ────────────────────────────────────────────────────────

    private function changeStatus(Request $request, int $id, string $status, string $label): JsonResponse
    {
        $user = $request->attributes->get('authUser');
        if (!$user || !$user->isOwner()) {
            return response()->json(['message' => 'Hanya owner yang dapat ' . $label . ' karyawan'], 403);
        }

        $employee = Employee::with('branch')->find($id);
        if (!$employee) {
            return response()->json(['message' => 'Karyawan tidak ditemukan'], 404);
        }

        // Pastikan karyawan ini milik cabang dari bisnis owner yang login
        $owned = Business::where('owner_id', $user->id)
            ->whereHas('cabangs', fn($q) => $q->where('id', $employee->branch_id))
            ->exists();
        if (!$owned) {
            return response()->json(['message' => 'Karyawan tidak milik usaha Anda'], 403);
        }

        try {
            $employee->update(['status' => $status]);
            return response()->json([
                'success' => true,
                'message' => "Karyawan berhasil {$label}",
                'data'    => new EmployeeResource($employee->fresh()->load('branch')),
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => "Gagal {$label} karyawan",
                'errors'  => ['exception' => $e->getMessage()],
            ], 500);
        }
    }
}
