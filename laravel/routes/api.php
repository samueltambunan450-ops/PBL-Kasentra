<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BranchHeadController;
use App\Http\Controllers\Api\CabangController;
use App\Http\Controllers\Api\EmployeeController;
use App\Http\Controllers\Api\KaryawanController;
use App\Http\Controllers\Api\KategoriController;
use App\Http\Controllers\Api\TransaksiController;
use App\Http\Controllers\Api\UserController;
use Illuminate\Support\Facades\Route;

Route::middleware('cors.api')->group(function (): void {
    Route::prefix('auth')->group(function (): void {
        Route::post('/google', [AuthController::class, 'google']);
        Route::post('/manual-login', [AuthController::class, 'manualLogin']);
        Route::middleware('auth.token')->group(function (): void {
            Route::get('/me', [AuthController::class, 'me']);
            Route::post('/logout', [AuthController::class, 'logout']);
            // validateInvitation dipakai oleh RedeemInvitePage (kepala cabang)
            Route::post('/invitation/validate', [AuthController::class, 'validateInvitation']);
            // generateInvitation lama (untuk karyawan biasa) dihapus dari route publik
            // Undangan kepala cabang pakai: POST /api/branches/{id}/invite
            Route::post('/setup-business', [AuthController::class, 'setupBusiness']);
        });
    });

    Route::middleware('auth.token')->group(function (): void {
        // ── Cabang (existing) ───────────────────────────────────────────────────
        Route::get('/cabangs', [CabangController::class, 'index']);
        Route::post('/cabangs', [CabangController::class, 'store']);
        Route::put('/cabangs/{id}', [CabangController::class, 'update']);
        Route::delete('/cabangs/{id}', [CabangController::class, 'destroy']);
        Route::put('/cabangs/{id}/jam-operasional', [CabangController::class, 'updateJamOperasional']);

        // ── Kategori ────────────────────────────────────────────────────────────
        Route::get('/kategoris', [KategoriController::class, 'index']);
        Route::post('/kategoris', [KategoriController::class, 'store']);
        Route::put('/kategoris/{id}', [KategoriController::class, 'update']);
        Route::delete('/kategoris/{id}', [KategoriController::class, 'destroy']);

        // ── Transaksi ───────────────────────────────────────────────────────────
        Route::get('/transaksis', [TransaksiController::class, 'index']);
        Route::post('/transaksis', [TransaksiController::class, 'store']);
        Route::put('/transaksis/{id}', [TransaksiController::class, 'update']);
        Route::delete('/transaksis/{id}', [TransaksiController::class, 'destroy']);
        Route::get('/transaksis/cek-pengeluaran-hari-ini', [TransaksiController::class, 'cekPengeluaranHariIni']);

        // ── Karyawan (existing - login-based) ───────────────────────────────────
        Route::get('/karyawans', [KaryawanController::class, 'index']);
        Route::post('/karyawans', [KaryawanController::class, 'store']);
        Route::put('/karyawans/{id}', [KaryawanController::class, 'update']);
        Route::delete('/karyawans/{id}', [KaryawanController::class, 'destroy']);

        // ── Users ───────────────────────────────────────────────────────────────
        Route::get('/users/kepala-cabang', [UserController::class, 'indexKepalaCabang']);
        Route::delete('/users/{id}', [UserController::class, 'destroy']);

        // ── Businesses & Branches (Owner) ───────────────────────────────────────
        Route::get('/businesses/{id}/branches', [BranchHeadController::class, 'branches']);
        Route::get('/businesses/{id}/branches/status', [BranchHeadController::class, 'branchStatus']);

        // ── Kepala Cabang management ─────────────────────────────────────────────
        Route::post('/branches/{id}/invite', [BranchHeadController::class, 'invite']);
        Route::get('/branches/{id}/branch-head', [BranchHeadController::class, 'show']);

        // ── Employees (non-login karyawan, dikelola kepala cabang) ───────────────
        Route::get('/branches/{id}/employees', [EmployeeController::class, 'index']);
        Route::post('/branches/{id}/employees', [EmployeeController::class, 'store']);
        Route::put('/employees/{id}', [EmployeeController::class, 'update']);
        Route::delete('/employees/{id}', [EmployeeController::class, 'destroy']);
        // Approval oleh Owner
        Route::patch('/employees/{id}/approve', [EmployeeController::class, 'approve']);
        Route::patch('/employees/{id}/reject', [EmployeeController::class, 'reject']);
        Route::get('/businesses/{businessId}/employees/pending', [EmployeeController::class, 'pendingByBusiness']);
        Route::get('/businesses/{businessId}/employees/pending/count', [EmployeeController::class, 'pendingCount']);
        Route::get('/branches/{id}/employees/total-salary', [EmployeeController::class, 'totalSalary']);

        // ── Invitation redeem (alias untuk Flutter) ──────────────────────────────
        Route::post('/invitation/redeem', [AuthController::class, 'validateInvitation']);
    });
});
