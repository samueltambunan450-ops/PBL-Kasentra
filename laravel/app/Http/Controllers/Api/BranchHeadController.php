<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\BranchHeadResource;
use App\Http\Resources\BranchStatusResource;
use App\Models\BranchHead;
use App\Models\Business;
use App\Models\Cabang;
use App\Models\Invitation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Throwable;

class BranchHeadController extends Controller
{
    /**
     * POST /api/branches/{id}/invite
     * Owner menambahkan kepala cabang + generate kode undangan sekali pakai.
     */
    public function invite(Request $request, int $id): JsonResponse
    {
        $user = $request->attributes->get('authUser');
        if (!$user || !$user->isOwner()) {
            return response()->json(['message' => 'Hanya owner yang dapat menambahkan kepala cabang'], 403);
        }

        $cabang = Cabang::find($id);
        if (!$cabang) {
            return response()->json(['message' => 'Cabang tidak ditemukan'], 404);
        }

        // Validasi kepemilikan:
        // Jika cabang punya business_id → pastikan business itu milik owner ini
        // Jika cabang TIDAK punya business_id (data lama/legacy) → lolos, cukup owner
        if ($cabang->business_id !== null) {
            $owned = Business::where('id', $cabang->business_id)
                ->where('owner_id', $user->id)
                ->exists();

            if (!$owned) {
                return response()->json(['message' => 'Cabang tidak dimiliki oleh usaha Anda'], 403);
            }
        }

        $data = $request->validate([
            'nama'  => ['required', 'string', 'max:255'],
            'no_hp' => ['required', 'string', 'max:20'],
        ]);

        try {
            $result = DB::transaction(function () use ($user, $cabang, $data) {
                // Nonaktifkan semua kepala cabang lama yang masih aktif di cabang ini
                // sehingga tidak ada dua kepala cabang aktif sekaligus
                BranchHead::where('branch_id', $cabang->id)
                    ->where('is_active', true)
                    ->update(['is_active' => false]);

                // Buat record branch_head baru
                $branchHead = BranchHead::create([
                    'branch_id' => $cabang->id,
                    'user_id'   => null,
                    'nama'      => $data['nama'],
                    'no_hp'     => $data['no_hp'],
                    'is_active' => false,
                ]);

                // Generate kode undangan unik sekali pakai
                do {
                    $code = strtoupper(Str::random(8));
                } while (Invitation::where('code', $code)->exists());

                $invitation = Invitation::create([
                    'owner_id'       => $user->id,
                    'cabang_id'      => $cabang->id,
                    'branch_head_id' => $branchHead->id,
                    'code'           => $code,
                    'expires_at'     => now()->addDays(7),
                ]);

                return compact('branchHead', 'invitation');
            });

            return response()->json([
                'success' => true,
                'message' => 'Kepala cabang berhasil ditambahkan',
                'data'    => [
                    'branch_head'     => new BranchHeadResource($result['branchHead']->load(['branch', 'invitation'])),
                    'invitation_code' => $result['invitation']->code,
                    'expires_at'      => $result['invitation']->expires_at,
                ],
            ], 201);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal menambahkan kepala cabang',
                'errors'  => ['exception' => $e->getMessage()],
            ], 500);
        }
    }

    /**
     * GET /api/branches/{id}/branch-head
     * Detail kepala cabang aktif pada cabang tertentu.
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $user = $request->attributes->get('authUser');
        if (!$user) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        try {
            $cabang = Cabang::find($id);
            if (!$cabang) {
                return response()->json(['message' => 'Cabang tidak ditemukan'], 404);
            }

            $branchHeads = BranchHead::where('branch_id', $id)
                ->with(['user', 'invitation'])
                ->orderByDesc('is_active')
                ->orderByDesc('created_at')
                ->get();

            return response()->json([
                'success' => true,
                'message' => 'Data kepala cabang',
                'data'    => BranchHeadResource::collection($branchHeads),
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat data kepala cabang',
                'errors'  => ['exception' => $e->getMessage()],
            ], 500);
        }
    }

    /**
     * GET /api/businesses/{id}/branches/status
     * Status setiap cabang milik usaha (kepala cabang aktif atau belum).
     * Cabang legacy (business_id null) juga di-include karena dimiliki owner.
     */
    public function branchStatus(Request $request, int $businessId): JsonResponse
    {
        $user = $request->attributes->get('authUser');
        if (!$user || !$user->isOwner()) {
            return response()->json(['message' => 'Hanya owner yang dapat melihat status cabang'], 403);
        }

        $business = Business::where('id', $businessId)
            ->where('owner_id', $user->id)
            ->first();

        if (!$business) {
            return response()->json(['message' => 'Usaha tidak ditemukan'], 404);
        }

        try {
            $cabangs = Cabang::where(function ($q) use ($businessId) {
                    $q->where('business_id', $businessId)
                      ->orWhereNull('business_id');
                })
                ->with([
                    'activeBranchHead',
                    'branchHeads' => fn($q) => $q->with([
                        'invitation' => fn($qi) => $qi->whereNull('used_at')
                            ->where('expires_at', '>', now()),
                    ]),
                ])
                ->orderBy('id')
                ->get();

            $data = $cabangs->map(function ($cabang) {
                $activeBranchHead = $cabang->activeBranchHead;
                $pendingHead = $cabang->branchHeads
                    ->where('is_active', false)
                    ->first(fn($bh) => $bh->invitation !== null);

                if ($activeBranchHead) {
                    $headStatus = 'active';
                } elseif ($pendingHead) {
                    $headStatus = 'pending';
                } else {
                    $headStatus = 'empty';
                }

                return [
                    'id'                 => $cabang->id,
                    'nama_cabang'        => $cabang->nama,
                    'alamat'             => $cabang->alamat ?? '',
                    'head_status'        => $headStatus,
                    'has_active_head'    => $headStatus === 'active',
                    'active_branch_head' => $activeBranchHead
                        ? [
                            'id'      => $activeBranchHead->id,
                            'nama'    => $activeBranchHead->nama,
                            'no_hp'   => $activeBranchHead->no_hp,
                            'user_id' => $activeBranchHead->user_id,
                        ]
                        : null,
                    'pending_branch_head' => $pendingHead
                        ? [
                            'id'             => $pendingHead->id,
                            'nama'           => $pendingHead->nama,
                            'no_hp'          => $pendingHead->no_hp,
                            'invitation_code'=> $pendingHead->invitation->code ?? null,
                            'expires_at'     => $pendingHead->invitation->expires_at ?? null,
                        ]
                        : null,
                    'total_branch_heads' => $cabang->branchHeads->count(),
                ];
            });

            return response()->json([
                'success' => true,
                'message' => 'Status cabang',
                'data'    => $data,
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal memuat status cabang',
                'errors'  => ['exception' => $e->getMessage()],
            ], 500);
        }
    }

    /**
     * GET /api/businesses/{id}/branches
     * List cabang milik usaha.
     */
    public function branches(Request $request, int $businessId): JsonResponse
    {
        $user = $request->attributes->get('authUser');
        if (!$user || !$user->isOwner()) {
            return response()->json(['message' => 'Hanya owner yang dapat melihat cabang'], 403);
        }

        $business = Business::where('id', $businessId)
            ->where('owner_id', $user->id)
            ->first();

        if (!$business) {
            return response()->json(['message' => 'Usaha tidak ditemukan'], 404);
        }

        $cabangs = Cabang::where('business_id', $businessId)
            ->with(['activeBranchHead'])
            ->orderBy('id')
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Daftar cabang',
            'data'    => $cabangs->map(fn($c) => [
                'id'           => $c->id,
                'nama_cabang'  => $c->nama,
                'alamat'       => $c->alamat,
                'modal_awal'   => (float) $c->modal_awal,
                'has_active_head' => $c->activeBranchHead !== null,
            ]),
        ]);
    }
}
