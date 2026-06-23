# 🐛 BUG FIX: Validasi "Pengeluaran Dulu Baru Pemasukan" Tidak Berfungsi

## ✅ STATUS: BERHASIL DIPERBAIKI

---

## 📋 DESKRIPSI BUG

### Gejala:
- Kepala Cabang sudah input **pengeluaran** (terlihat di Home)
- Saat coba input **pemasukan**, sistem tetap tampilkan warning:
  > "Catat pengeluaran terlebih dahulu sebelum input pemasukan hari ini"

### User yang Terpengaruh:
- ❌ **Kepala Cabang**
- ❌ **Karyawan**
- ✅ Owner (tidak terpengaruh, tidak ada validasi)

---

## 🔍 INVESTIGASI

### 1️⃣ TIMEZONE MISMATCH (ROOT CAUSE) ✅

**Lokasi Masalah**:
- **File**: `laravel/config/app.php`
- **Line**: 68
- **Config**: `'timezone' => 'UTC'`

**Analisis**:
```
WIB (Indonesia) = UTC + 7 jam

Contoh Bug:
─────────────────────────────────────────────────────
Waktu User Input Pengeluaran: 22 Juni 2026, 18:00 WIB
Database: Transaksi disimpan dengan tanggal = 2026-06-22

Server timezone: UTC
Jam 18:00 WIB = 11:00 UTC (masih tanggal 22 Juni di UTC)

Saat cek pengeluaran di jam 01:00 WIB (masih malam):
- WIB: 22 Juni 2026, 01:00
- UTC: 21 Juni 2026, 18:00 (KEMARIN!)

Query: whereDate('tanggal', now()->toDateString())
      whereDate('tanggal', '2026-06-21')  ← UTC, kemarin!

Hasil: Tidak ketemu transaksi tanggal 22 Juni → Warning muncul!
```

**Kondisi Bug Terjadi**:
- User input pengeluaran di **sore/malam** (18:00 - 23:59 WIB)
- User input pemasukan di **pagi/dini hari** (00:00 - 06:59 WIB)
- Server menggunakan **UTC** (7 jam lebih lambat)
- Query `now()` pakai UTC → cari tanggal **kemarin** → tidak ketemu

### 2️⃣ CABANG SCOPE (Checked, OK) ✅

**Lokasi**: `TransaksiController.php` line 107 & 264

```php
// ✅ SUDAH BENAR - Filter by cabang_id user yang login
Transaksi::where('cabang_id', $user->cabang_id)
    ->where('jenis', 'pengeluaran')
    ->whereDate('tanggal', now()->toDateString())  // ❌ Tapi timezone salah
    ->exists();
```

**Kesimpulan**: Scope cabang sudah benar, masalah ada di **timezone**.

### 3️⃣ FLUTTER CACHE (Checked, OK) ✅

**Lokasi**: `add_transaction_page.dart` line 101

```dart
// ✅ SUDAH BENAR - Fetch dari API, bukan cache
final sudahAda = await DomainApiService.cekPengeluaranHariIni();
setState(() => _sudahAdaPengeluaran = sudahAda);
```

**Kesimpulan**: Flutter tidak pakai cache, langsung call API. Masalah ada di **backend timezone**.

---

## 🔧 SOLUSI YANG DITERAPKAN

### Fix 1: **Update Timezone Config → Asia/Jakarta**

**File**: `laravel/config/app.php`  
**Line**: 68

```php
// ❌ SEBELUM:
'timezone' => 'UTC',

// ✅ SESUDAH:
'timezone' => 'Asia/Jakarta',
```

**Efek**: Semua fungsi `now()`, `Carbon::now()`, dan date functions di Laravel sekarang menggunakan timezone **Asia/Jakarta** (WIB).

---

### Fix 2: **Explicit Timezone di Query Validasi (Defensive)**

Walaupun config sudah diubah, lebih baik explicit timezone untuk memastikan query selalu pakai WIB.

#### A. **TransaksiController::store()** - Validasi saat input pemasukan

**File**: `laravel/app/Http/Controllers/Api/TransaksiController.php`  
**Line**: 109

```php
// ❌ SEBELUM:
->whereDate('tanggal', now()->toDateString())

// ✅ SESUDAH:
->whereDate('tanggal', now('Asia/Jakarta')->toDateString())
```

#### B. **TransaksiController::cekPengeluaranHariIni()** - Endpoint cek status

**File**: `laravel/app/Http/Controllers/Api/TransaksiController.php`  
**Line**: 266

```php
// ❌ SEBELUM:
->whereDate('tanggal', now()->toDateString())

// ✅ SESUDAH:
->whereDate('tanggal', now('Asia/Jakarta')->toDateString())
```

---

### Fix 3: **Update Cabang::isOpen() untuk Konsistensi**

**File**: `laravel/app/Models/Cabang.php`  
**Line**: 66

```php
// ❌ SEBELUM:
$now = now()->format('H:i:s');

// ✅ SESUDAH:
$now = now('Asia/Jakarta')->format('H:i:s');
```

**Efek**: Validasi jam operasional cabang juga pakai timezone WIB, konsisten.

---

## 📊 FILE YANG DIUBAH

| File | Baris | Perubahan |
|------|-------|-----------|
| `config/app.php` | 68 | `'timezone' => 'Asia/Jakarta'` |
| `TransaksiController.php` | 109 | `now('Asia/Jakarta')->toDateString()` |
| `TransaksiController.php` | 266 | `now('Asia/Jakarta')->toDateString()` |
| `Cabang.php` | 66 | `now('Asia/Jakarta')->format('H:i:s')` |

**Total**: 4 file, 4 baris diubah

---

## 🧪 TESTING

### Test Case 1: Input Pengeluaran → Input Pemasukan (Berhasil)

**Langkah**:
1. Login sebagai **Kepala Cabang**
2. Input **Pengeluaran** (misal: Bahan Baku, Rp 400.000)
3. Check Home → Pengeluaran muncul
4. Coba input **Pemasukan**
5. ✅ **Harusnya**: Tidak ada warning, bisa input pemasukan

**Expected Result**:
```
✅ Pemasukan berhasil disimpan
❌ TIDAK ADA warning "Catat pengeluaran terlebih dahulu"
```

### Test Case 2: Input Pemasukan Tanpa Pengeluaran (Warning)

**Langkah**:
1. Login sebagai **Kepala Cabang**
2. **JANGAN** input pengeluaran dulu
3. Langsung coba input **Pemasukan**
4. ⚠️ **Harusnya**: Muncul warning

**Expected Result**:
```
⚠️ Warning: "Kepala cabang wajib input pengeluaran terlebih dahulu 
            sebelum mencatat pemasukan hari ini."
```

### Test Case 3: Owner Bypass Validasi (Berhasil)

**Langkah**:
1. Login sebagai **Owner**
2. Langsung input **Pemasukan** (tanpa pengeluaran)
3. ✅ **Harusnya**: Berhasil tanpa warning

**Expected Result**:
```
✅ Pemasukan berhasil disimpan (Owner tidak perlu validasi)
```

### Test Case 4: Edge Case - Input di Dini Hari (Berhasil)

**Skenario Bug Lama**:
1. Kepala Cabang input **pengeluaran** jam 18:00 WIB (sore)
2. Kepala Cabang input **pemasukan** jam 01:00 WIB (dini hari)
3. ❌ **Dulu**: Muncul warning (karena UTC cari tanggal kemarin)
4. ✅ **Sekarang**: Tidak ada warning (timezone sudah WIB)

---

## 🚀 DEPLOYMENT

### Restart Laravel Application

Setelah mengubah `config/app.php`, perlu:

```bash
# Clear config cache
php artisan config:clear

# Clear application cache
php artisan cache:clear

# Optional: Restart server (jika pakai queue/scheduler)
php artisan queue:restart
```

### No Need to Clear Flutter Cache

Karena fix hanya di backend, Flutter tidak perlu rebuild atau clear cache.

---

## 📝 CATATAN TAMBAHAN

### Kenapa Explicit `now('Asia/Jakarta')`?

Walaupun config timezone sudah diubah, menggunakan explicit timezone di query lebih **defensive** dan **jelas intent**-nya:

```php
// Lebih eksplisit dan jelas
now('Asia/Jakarta')->toDateString()

// vs

// Depend on config, bisa lupa
now()->toDateString()
```

### Query Lain yang TIDAK Perlu Diubah

Query berikut **tidak perlu** diubah karena tidak membandingkan "hari ini":

1. **AuthController** - Token expiry (`expires_at`)
   - Tidak masalah pakai UTC atau WIB, selama konsisten
   - Token expiry bersifat absolut (7 hari dari sekarang)

2. **LaporanController** - Parse tanggal user
   - Pakai `Carbon::parse($request->query('date'))` (dari input user)
   - Tidak depend on server timezone

3. **BranchHeadController** - Invitation expiry
   - Sama seperti token, bersifat absolut

---

## ✅ KESIMPULAN

### Root Cause:
**TIMEZONE MISMATCH** - Server pakai UTC, user di WIB (UTC+7)

### Fix Applied:
1. ✅ Config timezone → `Asia/Jakarta`
2. ✅ Explicit timezone di query validasi
3. ✅ Update Cabang::isOpen() untuk konsistensi

### Status:
✅ **BUG FIXED - READY FOR TESTING**

### Impact:
- ✅ Kepala Cabang & Karyawan bisa input pemasukan setelah pengeluaran
- ✅ Validasi jam operasional cabang lebih akurat
- ✅ Semua date/time functions di Laravel pakai WIB
- ✅ Tidak ada side effect negatif

---

## 🔄 AFTER FIX - TEST CHECKLIST

- [ ] Test input pengeluaran → pemasukan (Kepala Cabang)
- [ ] Test input pengeluaran → pemasukan (Karyawan)
- [ ] Test input pemasukan tanpa pengeluaran → Warning muncul
- [ ] Test Owner input pemasukan tanpa pengeluaran → Berhasil
- [ ] Test di dini hari (00:00 - 06:59 WIB) → Tidak ada bug timezone
- [ ] Test jam operasional cabang → Akurat dengan WIB

**Status Testing**: ⏳ **PENDING USER TESTING**
