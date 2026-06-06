# KASENTRA Backend Smoke Test

## 1) Setup awal

1. Isi `.env`:
   - `FIREBASE_API_KEY=...`
   - `OWNER_EMAIL=...`
2. Jalankan migration + seeder:
   - `php artisan migrate:fresh --seed`
3. Start server:
   - `php artisan serve`

## 2) Login Google -> token API

Gunakan Firebase ID token dari Flutter login, lalu kirim ke backend:

```bash
curl -X POST http://127.0.0.1:8000/api/auth/google \
  -H "Content-Type: application/json" \
  -d "{\"id_token\":\"<FIREBASE_ID_TOKEN>\"}"
```

Respons akan berisi:
- `token` (Bearer token API)
- `user` (profil + role)

## 3) Cek profil login

```bash
curl http://127.0.0.1:8000/api/auth/me \
  -H "Authorization: Bearer <API_TOKEN>"
```

## 4) Cek endpoint master

```bash
curl http://127.0.0.1:8000/api/cabangs \
  -H "Authorization: Bearer <API_TOKEN>"
```

```bash
curl http://127.0.0.1:8000/api/kategoris \
  -H "Authorization: Bearer <API_TOKEN>"
```

## 5) Tambah transaksi

```bash
curl -X POST http://127.0.0.1:8000/api/transaksis \
  -H "Authorization: Bearer <API_TOKEN>" \
  -H "Content-Type: application/json" \
  -d "{\"cabang_id\":1,\"jenis\":\"pemasukan\",\"nominal\":150000,\"tanggal\":\"2026-05-07\",\"keterangan\":\"Penjualan harian\"}"
```

## 6) Cek laporan

```bash
curl "http://127.0.0.1:8000/api/laporan/ringkasan?period=bulanan" \
  -H "Authorization: Bearer <API_TOKEN>"
```
