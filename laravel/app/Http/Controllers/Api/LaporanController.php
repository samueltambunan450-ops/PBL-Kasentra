<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Business;
use App\Models\Transaksi;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Carbon;

class LaporanController extends Controller
{
    public function ringkasan(Request $request)
    {
        $user = $this->authorizeOwner($request);
        [$start, $end] = $this->resolveRange($request);
        $cabangId = $request->query('cabang_id');

        $allowedCabangIds = $this->ownerCabangIds($user);

        $query = Transaksi::query()
            ->whereIn('cabang_id', $allowedCabangIds)
            ->whereBetween('tanggal', [$start, $end]);

        if ($cabangId && in_array((int)$cabangId, $allowedCabangIds->toArray())) {
            $query->where('cabang_id', $cabangId);
        }

        $pemasukan   = (clone $query)->where('jenis', 'pemasukan')->sum('nominal');
        $pengeluaran = (clone $query)->where('jenis', 'pengeluaran')->sum('nominal');

        return response()->json([
            'start'             => $start->toDateString(),
            'end'               => $end->toDateString(),
            'total_pemasukan'   => (int) $pemasukan,
            'total_pengeluaran' => (int) $pengeluaran,
            'saldo'             => (int) $pemasukan - (int) $pengeluaran,
        ]);
    }

    public function grafik(Request $request)
    {
        $user = $this->authorizeOwner($request);
        [$start, $end] = $this->resolveRange($request);
        $cabangId = $request->query('cabang_id');

        $allowedCabangIds = $this->ownerCabangIds($user);

        $query = Transaksi::query()
            ->select(['tanggal', 'jenis', DB::raw('SUM(nominal) as total')])
            ->whereIn('cabang_id', $allowedCabangIds)
            ->whereBetween('tanggal', [$start, $end])
            ->groupBy('tanggal', 'jenis')
            ->orderBy('tanggal');

        if ($cabangId && in_array((int)$cabangId, $allowedCabangIds->toArray())) {
            $query->where('cabang_id', $cabangId);
        }

        return response()->json($query->get());
    }

    public function transaksi(Request $request)
    {
        $user = $this->authorizeOwner($request);
        [$start, $end] = $this->resolveRange($request);
        $cabangId = $request->query('cabang_id');

        $allowedCabangIds = $this->ownerCabangIds($user);

        $query = Transaksi::with(['cabang', 'kategori', 'user'])
            ->whereIn('cabang_id', $allowedCabangIds)
            ->whereBetween('tanggal', [$start, $end])
            ->orderByDesc('tanggal');

        if ($cabangId && in_array((int)$cabangId, $allowedCabangIds->toArray())) {
            $query->where('cabang_id', $cabangId);
        }

        return response()->json($query->get());
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private function resolveRange(Request $request): array
    {
        $period = $request->query('period', 'bulanan');
        $date   = $request->query('date') ? Carbon::parse($request->query('date')) : now();

        return match ($period) {
            'harian'   => [$date->copy()->startOfDay(),   $date->copy()->endOfDay()],
            'mingguan' => [$date->copy()->startOfWeek(),  $date->copy()->endOfWeek()],
            default    => [$date->copy()->startOfMonth(), $date->copy()->endOfMonth()],
        };
    }

    private function authorizeOwner(Request $request)
    {
        $user = $request->attributes->get('authUser');
        abort_unless($user && $user->role === 'owner', 403, 'Forbidden');
        return $user;
    }

    /**
     * Kembalikan collection ID cabang yang benar-benar milik business owner ini.
     * Single source of truth untuk scoping semua query laporan.
     */
    private function ownerCabangIds($user): \Illuminate\Support\Collection
    {
        return Business::where('owner_id', $user->id)
            ->with('cabangs:id,business_id')
            ->get()
            ->flatMap(fn($b) => $b->cabangs->pluck('id'));
    }
}
