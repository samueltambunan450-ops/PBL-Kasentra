# Kebutuhan Fungsional & Nonfungsional — KASENTRA

**Aplikasi:** KASENTRA — Sistem Pembukuan Keuangan UMKM Multi-Cabang  
**Aktor:** Pemilik Usaha (Owner) & Karyawan

---

## 1. Kebutuhan Fungsional (Owner)

| Kode | Aktor | Nama Kebutuhan | Deskripsi |
|------|-------|----------------|-----------|
| F-01 | Owner | Login dengan Google | Owner dapat masuk ke aplikasi menggunakan akun Google dan diarahkan ke Dashboard Pemilik. |
| F-02 | Owner | Logout | Owner dapat keluar dari sesi aplikasi; token API dan data sesi lokal dihapus. |
| F-03 | Owner | Setup usaha baru | Pengguna baru dapat membuat usaha, mengisi jenis usaha, dan menambahkan cabang pertama; role berubah menjadi owner. |
| F-04 | Owner | Lihat dashboard keuangan | Owner dapat melihat ringkasan pemasukan, pengeluaran, saldo, grafik tren, dan transaksi terbaru. |
| F-05 | Owner | Filter dashboard | Owner dapat memfilter data dashboard berdasarkan cabang dan periode waktu. |
| F-06 | Owner | Tambah transaksi | Owner dapat mencatat transaksi pemasukan atau pengeluaran dengan nominal, tanggal, cabang, kategori, keterangan, foto bukti, dan flag modal kiriman. |
| F-07 | Owner | Lihat riwayat transaksi | Owner dapat melihat daftar seluruh transaksi dari semua cabang. |
| F-08 | Owner | Edit transaksi | Owner dapat memperbarui data transaksi yang sudah tercatat. |
| F-09 | Owner | Hapus transaksi | Owner dapat menghapus transaksi dengan konfirmasi terlebih dahulu. |
| F-10 | Owner | Kelola cabang (CRUD) | Owner dapat menambah, melihat, mengubah, dan menghapus data cabang (nama, alamat, modal awal, jam buka, jam tutup). |
| F-11 | Owner | Kelola karyawan (CRUD) | Owner dapat menambah, melihat, mengubah, dan menghapus data karyawan serta menetapkan cabang kerja. |
| F-12 | Owner | Generate kode undangan | Owner dapat membuat kode undangan per cabang agar karyawan baru dapat bergabung; kode berlaku 24 jam. |
| F-13 | Owner | Kelola kategori (CRUD) | Owner dapat menambah, melihat, mengubah, dan menghapus kategori transaksi (pemasukan/pengeluaran) dengan scope global atau per cabang. |
| F-14 | Owner | Lihat laporan keuangan | Owner dapat melihat laporan pemasukan, pengeluaran, laba bersih, dan grafik berdasarkan filter cabang dan periode (harian/mingguan/bulanan/kustom). |
| F-15 | Owner | Akses menu manajemen | Owner dapat mengakses menu Kelola Cabang, Kelola Karyawan, dan Kelola Kategori melalui halaman Profil. |

---

## 2. Kebutuhan Fungsional (Karyawan)

| Kode | Aktor | Nama Kebutuhan | Deskripsi |
|------|-------|----------------|-----------|
| F-16 | Karyawan | Login dengan Google | Karyawan dapat masuk ke aplikasi menggunakan akun Google dan diarahkan ke Dashboard Karyawan. |
| F-17 | Karyawan | Logout | Karyawan dapat keluar dari sesi aplikasi; token API dan data sesi lokal dihapus. |
| F-18 | Karyawan | Gabung via kode undangan | Pengguna baru dapat bergabung sebagai karyawan dengan memasukkan kode undangan valid dari owner. |
| F-19 | Karyawan | Lihat dashboard cabang | Karyawan dapat melihat pemasukan dan pengeluaran hari ini, saldo cabang, serta riwayat transaksi di cabangnya. |
| F-20 | Karyawan | Tambah transaksi pemasukan | Karyawan dapat mencatat pemasukan di cabangnya setelah ada pengeluaran pada hari yang sama. |
| F-21 | Karyawan | Tambah transaksi pengeluaran | Karyawan dapat mencatat pengeluaran di cabangnya selama cabang dalam jam operasional. |
| F-22 | Karyawan | Validasi jam operasional | Sistem menolak input transaksi karyawan jika cabang sedang tutup (di luar jam buka–tutup). |
| F-23 | Karyawan | Validasi urutan input | Sistem menolak input pemasukan karyawan jika belum ada pengeluaran yang dicatat pada hari yang sama. |
| F-24 | Karyawan | Upload foto bukti | Karyawan dapat melampirkan foto bukti transaksi secara opsional saat mencatat transaksi. |
| F-25 | Karyawan | Lihat riwayat transaksi cabang | Karyawan hanya dapat melihat transaksi yang tercatat di cabang tempat ia ditugaskan. |
| F-26 | Karyawan | Akses profil terbatas | Karyawan dapat melihat profil dan logout, tanpa akses ke menu manajemen dan laporan keuangan. |

---

## 3. Kebutuhan Nonfungsional

| Kode | Kategori | Nama Kebutuhan | Deskripsi | Aktor Terkait |
|------|----------|----------------|-----------|---------------|
| NF-01 | Keamanan | Autentikasi Google OAuth | Sistem menggunakan Firebase Google Sign-In dan token API untuk mengamankan akses pengguna. | Owner, Karyawan |
| NF-02 | Keamanan | Kontrol akses berbasis peran | Sistem membatasi fitur berdasarkan role (`owner`, `karyawan`, `pending`); karyawan tidak dapat mengakses fitur owner. | Owner, Karyawan |
| NF-03 | Keamanan | Validasi token API | Setiap permintaan ke API dilindungi token autentikasi; token kadaluarsa setelah 14 hari. | Owner, Karyawan |
| NF-04 | Kinerja | Respons API | Sistem API merespons permintaan data dalam waktu wajar (< 3 detik) pada kondisi jaringan normal. | Owner, Karyawan |
| NF-05 | Kinerja | Muat dashboard | Halaman dashboard dapat dimuat tanpa delay berlebihan setelah data tersedia dari server. | Owner, Karyawan |
| NF-06 | Ketersediaan | Koneksi internet | Aplikasi memerlukan koneksi internet aktif untuk sinkronisasi data dengan server Laravel. | Owner, Karyawan |
| NF-07 | Usabilitas | Antarmuka mobile-first | Aplikasi dirancang untuk perangkat mobile (Flutter) dengan navigasi tab yang mudah dipahami. | Owner, Karyawan |
| NF-08 | Usabilitas | Pesan error informatif | Sistem menampilkan pesan error yang jelas saat validasi gagal (mis. cabang tutup, kode undangan kadaluarsa). | Owner, Karyawan |
| NF-09 | Reliabilitas | Integritas data transaksi | Data transaksi tersimpan konsisten di database; penghapusan cabang menghapus data terkait secara cascade. | Owner |
| NF-10 | Reliabilitas | Kode undangan sekali pakai | Kode undangan hanya dapat digunakan satu kali dan otomatis kadaluarsa setelah 24 jam. | Owner, Karyawan |
| NF-11 | Skalabilitas | Multi-cabang | Sistem mendukung satu usaha dengan banyak cabang; owner dapat mengelola seluruh cabang dari satu akun. | Owner |
| NF-12 | Portabilitas | Cross-platform | Aplikasi Flutter dapat dijalankan di Android, iOS, dan web. | Owner, Karyawan |
| NF-13 | Maintainability | Arsitektur terpisah | Frontend (Flutter) dan backend (Laravel REST API) terpisah untuk memudahkan pengembangan dan pemeliharaan. | — |
| NF-14 | Validasi | Validasi input server-side | Semua input transaksi dan master data divalidasi di sisi server sebelum disimpan ke database. | Owner, Karyawan |
| NF-15 | Audit | Pencatatan pengguna transaksi | Setiap transaksi menyimpan `user_id` pencatat untuk keperluan pelacakan. | Owner, Karyawan |

---

## 4. Ringkasan

| Jenis | Jumlah | Rentang Kode |
|-------|--------|--------------|
| Kebutuhan Fungsional — Owner | 15 | F-01 s/d F-15 |
| Kebutuhan Fungsional — Karyawan | 11 | F-16 s/d F-26 |
| Kebutuhan Nonfungsional | 15 | NF-01 s/d NF-15 |
| **Total** | **41** | — |
