<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CabangController;
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
            Route::post('/invitation/validate', [AuthController::class, 'validateInvitation']);
            Route::post('/invitation/generate', [AuthController::class, 'generateInvitation']);
            Route::post('/setup-business', [AuthController::class, 'setupBusiness']);
        });
    });

    // Endpoint utama untuk Flutter (sesuai DomainApiService).
    Route::middleware('auth.token')->group(function (): void {
        Route::get('/cabangs', [CabangController::class, 'index']);
        Route::post('/cabangs', [CabangController::class, 'store']);
        Route::put('/cabangs/{id}', [CabangController::class, 'update']);
        Route::delete('/cabangs/{id}', [CabangController::class, 'destroy']);

        Route::get('/kategoris', [KategoriController::class, 'index']);
        Route::post('/kategoris', [KategoriController::class, 'store']);
        Route::put('/kategoris/{id}', [KategoriController::class, 'update']);
        Route::delete('/kategoris/{id}', [KategoriController::class, 'destroy']);

        Route::get('/transaksis', [TransaksiController::class, 'index']);
        Route::post('/transaksis', [TransaksiController::class, 'store']);
        Route::put('/transaksis/{id}', [TransaksiController::class, 'update']);
        Route::delete('/transaksis/{id}', [TransaksiController::class, 'destroy']);
        Route::get('/transaksis/cek-pengeluaran-hari-ini', [TransaksiController::class, 'cekPengeluaranHariIni']);

        Route::put('/cabangs/{id}/jam-operasional', [CabangController::class, 'updateJamOperasional']);

        Route::get('/karyawans', [KaryawanController::class, 'index']);
        Route::post('/karyawans', [KaryawanController::class, 'store']);
        Route::put('/karyawans/{id}', [KaryawanController::class, 'update']);
        Route::delete('/karyawans/{id}', [KaryawanController::class, 'destroy']);

        Route::get('/users/kepala-cabang', [UserController::class, 'indexKepalaCabang']);
        Route::delete('/users/{id}', [UserController::class, 'destroy']);
    });
});
