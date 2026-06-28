# Kebutuhan Fungsional & Nonfungsional — KASENTRA

**Aplikasi:** KASENTRA — Sistem Pembukuan Keuangan UMKM Multi-Cabang  
**Versi:** 2.0  
**Aktor:** Pemilik Usaha (Owner), Kepala Cabang, Karyawan

---

## 1. Kebutuhan Fungsional (Owner)

| Kode | Nama Kebutuhan | Deskripsi |
|------|----------------|-----------|
| F-01 | Login dengan Google | Owner dapat masuk ke aplikasi menggunakan akun Google dengan opsi pemilihan akun (prompt 'select_account') dan diarahkan ke Dashboard Pemilik. |
| F-02 | Logout | Owner dapat keluar dari sesi aplikasi; token API, data sesi lokal, dan sesi Google dihapus dengan benar. |
| F-03 | Setup usaha baru | Pengguna baru dapat membuat usaha, mengisi jenis usaha, dan menambahkan cabang pertama; role berubah menjadi owner. |
| F-04 | Lihat dashboard keuangan | Owner dapat melihat ringkasan pemasukan, pengeluaran, saldo, grafik tren, dan transaksi terbaru dari semua cabang dengan loading indicator yang konsisten. |
| F-05 | Filter dashboard per cabang | Owner dapat memfilter data dashboard berdasarkan cabang tertentu; filter memicu rekomputasi data dengan benar. |
| F-06 | Filter dashboard per periode | Owner dapat memfilter data dashboard berdasarkan periode waktu (hari ini, minggu ini, bulan ini, atau kustom). |
| F-07 | Tambah transaksi | Owner dapat mencatat transaksi pemasukan atau pengeluaran dengan nominal, tanggal, cabang, kategori, keterangan, foto bukti (opsional), dan flag modal kiriman. |
| F-08 | Upload foto bukti transaksi | Owner dapat mengunggah foto bukti transaksi; foto disimpan di storage server dan dapat diakses via API proxy dengan autentikasi. |
| F-09 | Lihat foto bukti transaksi | Owner dapat melihat foto bukti transaksi melalui endpoint API proxy yang menangani CORS dan autentikasi. |
| F-10 | Lihat riwayat transaksi | Owner dapat melihat daftar seluruh transaksi dari semua cabang dengan informasi creator (created_by_name) yang akurat. |
| F-11 | Filter riwayat transaksi | Owner dapat memfilter riwayat transaksi berdasarkan cabang, periode waktu, dan jenis transaksi. |
| F-12 | Edit transaksi | Owner dapat memperbarui data transaksi yang sudah tercatat termasuk mengubah foto bukti. |
| F-13 | Hapus transaksi | Owner dapat menghapus transaksi dengan konfirmasi terlebih dahulu; foto bukti terkait juga terhapus dari storage. |
| F-14 | Tambah cabang | Owner dapat menambah cabang baru dengan nama, alamat, modal awal, jam buka, jam tutup, dan zona waktu. |
| F-15 | Lihat daftar cabang | Owner dapat melihat semua cabang miliknya dengan informasi lengkap termasuk status operasional. |
| F-16 | Edit cabang | Owner dapat mengubah data cabang (nama, alamat, jam operasional, zona waktu) yang sudah ada. |
| F-17 | Hapus cabang | Owner dapat menghapus cabang; sistem menolak penghapusan jika cabang memiliki transaksi, Kepala Cabang aktif, atau karyawan aktif dengan pesan error yang informatif. |
| F-18 | Generate kode undangan | Owner dapat membuat kode undangan per cabang dengan expired_at otomatis 24 jam untuk rekrutmen karyawan atau Kepala Cabang. |
| F-19 | Lihat daftar kode undangan | Owner dapat melihat semua kode undangan aktif dan kadaluarsa per cabang dengan informasi expired_at. |
| F-20 | Hapus kode undangan | Owner dapat menghapus kode undangan yang tidak terpakai atau sudah kadaluarsa. |
| F-21 | Tambah karyawan non-login | Owner dapat menambah data karyawan yang tidak memerlukan akses login (karyawan lapangan/shift) dengan nama, email (opsional), dan penugasan cabang. |
| F-22 | Lihat daftar karyawan | Owner dapat melihat semua karyawan (login dan non-login) dengan status aktif/nonaktif per cabang. |
| F-23 | Edit data karyawan | Owner dapat mengubah data karyawan termasuk nama, email, cabang penugasan, dan gaji. |
| F-24 | Nonaktifkan karyawan | Owner dapat menonaktifkan karyawan tanpa menghapus data historis; karyawan nonaktif tidak muncul di list aktif. |
| F-25 | Hapus data karyawan | Owner dapat menghapus data karyawan yang sudah tidak bekerja; transaksi historis tetap tersimpan. |
| F-26 | Auto-calculate gaji karyawan | Sistem otomatis menghitung gaji karyawan berdasarkan laba bersih cabang dengan persentase yang dapat dikonfigurasi Owner. |
| F-27 | Kelola approval karyawan pending | Owner dapat melihat daftar karyawan dengan status 'pending' (sudah daftar via kode undangan tapi belum diapprove). |
| F-28 | Approve karyawan pending | Owner dapat meng-approve karyawan pending; role berubah menjadi 'karyawan' dan mendapat akses ke cabang yang sesuai. |
| F-29 | Reject karyawan pending | Owner dapat menolak karyawan pending; user tersebut tidak mendapat akses dan status tetap pending atau dihapus. |
| F-30 | Badge notifikasi approval | Dashboard Owner menampilkan badge jumlah karyawan pending yang perlu di-approve; badge auto-refresh saat dashboard dimuat. |
| F-31 | Kelola Kepala Cabang | Owner dapat mengelola Kepala Cabang sebagai role terpisah dengan hak akses berbeda dari karyawan biasa. |
| F-32 | Approve Kepala Cabang | Owner dapat meng-approve user pending menjadi Kepala Cabang; role berubah menjadi 'kepala_cabang' dan mendapat akses manajemen cabang. |
| F-33 | Lihat status Kepala Cabang | Owner dapat melihat daftar cabang dengan status Kepala Cabang (sudah ada/belum ada) per cabang. |
| F-34 | Tambah kategori transaksi | Owner dapat menambah kategori transaksi baru (pemasukan/pengeluaran) dengan scope global (semua cabang) atau spesifik per cabang. |
| F-35 | Lihat daftar kategori | Owner dapat melihat semua kategori transaksi yang telah dibuat, difilter berdasarkan scope dan cabang. |
| F-36 | Edit kategori transaksi | Owner dapat mengubah nama dan scope kategori transaksi yang sudah ada. |
| F-37 | Hapus kategori transaksi | Owner dapat menghapus kategori transaksi; sistem menolak penghapusan jika kategori masih digunakan oleh transaksi aktif. |
| F-38 | Lihat laporan keuangan | Owner dapat melihat laporan pemasukan, pengeluaran, laba bersih, dan grafik berdasarkan filter cabang dan periode (harian/mingguan/bulanan/kustom) dengan loading indicator. |
| F-39 | Filter laporan per cabang | Owner dapat memfilter laporan keuangan per cabang tertentu; filter memicu rekomputasi data dengan benar. |
| F-40 | Filter laporan per periode | Owner dapat memfilter laporan keuangan berdasarkan periode (hari ini, minggu ini, bulan ini, atau rentang kustom). |
| F-41 | Export laporan PDF | Owner dapat mengekspor laporan keuangan ke format PDF dengan header bisnis, tabel transaksi, dan grafik menggunakan simbol text (bukan emoji) untuk kompatibilitas rendering. |
| F-42 | Atur threshold transaksi besar | Owner dapat mengatur batas nominal transaksi besar per bisnis melalui halaman pengaturan; threshold digunakan untuk notifikasi transaksi mencurigakan. |
| F-43 | Lihat notifikasi transaksi besar | Owner dapat melihat badge notifikasi jumlah transaksi yang melebihi threshold dan belum ditinjau di dashboard. |
| F-44 | Review transaksi besar | Owner dapat melihat daftar transaksi yang melebihi threshold dengan detail cabang, nominal, kategori, keterangan, dan creator. |
| F-45 | Tandai transaksi sudah ditinjau | Owner dapat menandai transaksi besar sebagai sudah ditinjau (is_reviewed = true); transaksi hilang dari list dan badge berkurang. |
| F-46 | Akses menu manajemen | Owner dapat mengakses menu Kelola Cabang, Kelola Karyawan, Kelola Kategori, Laporan Keuangan, Approval Karyawan, dan Pengaturan Threshold melalui halaman Profil. |

---

## 2. Kebutuhan Fungsional (Kepala Cabang)

| Kode | Nama Kebutuhan | Deskripsi |
|------|----------------|-----------|
| F-47 | Login dengan Google | Kepala Cabang dapat masuk ke aplikasi menggunakan akun Google dengan opsi pemilihan akun dan diarahkan ke Dashboard Kepala Cabang. |
| F-48 | Logout | Kepala Cabang dapat keluar dari sesi aplikasi; token API dan data sesi lokal dihapus dengan benar. |
| F-49 | Gabung via kode undangan | Pengguna baru dapat bergabung sebagai Kepala Cabang dengan memasukkan kode undangan valid dari owner; status awal 'pending' menunggu approval. |
| F-50 | Lihat dashboard cabang | Kepala Cabang dapat melihat pemasukan dan pengeluaran per periode, saldo cabang, grafik tren, dan transaksi terbaru di cabangnya dengan loading indicator yang konsisten. |
| F-51 | Filter dashboard per periode | Kepala Cabang dapat memfilter data dashboard berdasarkan periode waktu (hari ini, minggu ini, bulan ini, atau kustom); filter memicu rekomputasi data. |
| F-52 | Tambah transaksi pemasukan | Kepala Cabang dapat mencatat pemasukan di cabangnya tanpa batasan jam operasional atau urutan input (lebih fleksibel dari karyawan biasa). |
| F-53 | Tambah transaksi pengeluaran | Kepala Cabang dapat mencatat pengeluaran di cabangnya tanpa batasan jam operasional atau validasi urutan input. |
| F-54 | Upload foto bukti transaksi | Kepala Cabang dapat mengunggah foto bukti transaksi; foto dapat diakses via API proxy dengan autentikasi. |
| F-55 | Lihat foto bukti transaksi | Kepala Cabang dapat melihat foto bukti transaksi melalui endpoint API proxy. |
| F-56 | Edit transaksi cabang | Kepala Cabang dapat mengubah data transaksi yang tercatat di cabangnya termasuk mengubah foto bukti. |
| F-57 | Hapus transaksi cabang | Kepala Cabang dapat menghapus transaksi di cabangnya dengan konfirmasi terlebih dahulu. |
| F-58 | Lihat riwayat transaksi cabang | Kepala Cabang dapat melihat daftar transaksi yang tercatat di cabangnya dengan informasi creator yang akurat. |
| F-59 | Filter riwayat transaksi | Kepala Cabang dapat memfilter riwayat transaksi berdasarkan periode waktu dan jenis transaksi. |
| F-60 | Akses laporan keuangan cabang | Kepala Cabang dapat melihat laporan keuangan cabangnya dengan grafik dan statistik per periode. |
| F-61 | Export laporan cabang PDF | Kepala Cabang dapat mengekspor laporan keuangan cabangnya ke format PDF. |
| F-62 | Notifikasi threshold otomatis | Saat Kepala Cabang input transaksi yang melebihi threshold bisnis, sistem otomatis membuat notifikasi untuk Owner (tanpa intervensi Kepala Cabang). |
| F-63 | Lihat profil cabang | Kepala Cabang dapat melihat informasi profil cabang termasuk nama, alamat, jam operasional, dan zona waktu. |
| F-64 | Akses menu terbatas | Kepala Cabang hanya dapat mengakses fitur manajemen cabangnya; tidak dapat mengakses data cabang lain atau fitur owner-only. |

---

## 3. Kebutuhan Fungsional (Karyawan)

| Kode | Nama Kebutuhan | Deskripsi |
|------|----------------|-----------|
| F-65 | Login dengan Google | Karyawan dapat masuk ke aplikasi menggunakan akun Google dengan opsi pemilihan akun dan diarahkan ke Dashboard Karyawan. |
| F-66 | Logout | Karyawan dapat keluar dari sesi aplikasi; token API dan data sesi lokal dihapus. |
| F-67 | Gabung via kode undangan | Pengguna baru dapat bergabung sebagai karyawan dengan memasukkan kode undangan valid dari owner; status awal 'pending' menunggu approval. |
| F-68 | Lihat dashboard cabang | Karyawan dapat melihat pemasukan dan pengeluaran hari ini, saldo cabang, dan riwayat transaksi di cabangnya. |
| F-69 | Tambah transaksi pemasukan | Karyawan dapat mencatat pemasukan di cabangnya hanya setelah ada pengeluaran pada hari yang sama (validasi urutan input). |
| F-70 | Tambah transaksi pengeluaran | Karyawan dapat mencatat pengeluaran di cabangnya selama cabang dalam jam operasional berdasarkan zona waktu cabang. |
| F-71 | Validasi jam operasional | Sistem menolak input transaksi karyawan jika cabang sedang tutup (di luar jam buka–tutup) dengan pesan error yang informatif. |
| F-72 | Validasi urutan input | Sistem menolak input pemasukan karyawan jika belum ada pengeluaran yang dicatat pada hari yang sama dengan pesan error yang jelas. |
| F-73 | Upload foto bukti | Karyawan dapat melampirkan foto bukti transaksi secara opsional saat mencatat transaksi. |
| F-74 | Lihat riwayat transaksi cabang | Karyawan hanya dapat melihat transaksi yang tercatat di cabang tempat ia ditugaskan. |
| F-75 | Akses profil terbatas | Karyawan dapat melihat profil dan logout, tanpa akses ke menu manajemen, laporan keuangan, atau data cabang lain. |

---

## 4. Kebutuhan Nonfungsional

| Kode | Kategori | Nama Kebutuhan | Deskripsi | Metrik |
|------|----------|----------------|-----------|--------|
| NF-01 | Keamanan | Autentikasi Google OAuth | Sistem menggunakan Firebase Google Sign-In dengan parameter prompt 'select_account' untuk memaksa pemilihan akun setiap login, mencegah auto-login yang tidak diinginkan. | 100% login menggunakan Google OAuth |
| NF-02 | Keamanan | Kontrol akses berbasis peran | Sistem membatasi fitur berdasarkan role (owner, kepala_cabang, karyawan, pending); karyawan tidak dapat mengakses fitur Kepala Cabang atau Owner. | Role validation di setiap endpoint API |
| NF-03 | Keamanan | Validasi token API | Setiap permintaan ke API dilindungi token autentikasi Bearer; token kadaluarsa setelah 14 hari dan harus di-refresh. | 100% endpoint protected kecuali login/register |
| NF-04 | Keamanan | Isolasi data per bisnis | Sistem memastikan owner/karyawan hanya dapat mengakses data bisnis/cabang yang menjadi tanggung jawabnya (business_id/cabang_id scope). | Query scoping di semua controller |
| NF-05 | Keamanan | Foto bukti dengan autentikasi | Foto bukti transaksi hanya dapat diakses melalui API proxy dengan autentikasi token; tidak dapat diakses langsung via URL storage. | 100% foto request butuh auth token |
| NF-06 | Keamanan | CORS handling | Sistem menangani CORS dengan benar untuk akses cross-origin dari Flutter Web; foto dan API dapat diakses dari localhost development dan production domain. | Zero CORS errors di console browser |
| NF-07 | Keamanan | Logout bersih | Logout menghapus token lokal, session storage, dan memutus sesi Google dengan benar untuk mencegah akses tidak sah. | Token cleared & Google session terminated |
| NF-08 | Kinerja | Respons API cepat | Endpoint API merespons dalam waktu < 2 detik untuk query data transaksi dan dashboard pada kondisi jaringan normal. | 95% request < 2s response time |
| NF-09 | Kinerja | Loading indicator konsisten | Semua halaman menampilkan loading indicator (CircularProgressIndicator) saat data sedang di-fetch, bukan layar putih atau freeze. | 100% halaman punya loading state |
| NF-10 | Kinerja | Filter data real-time | Filter cabang dan periode di dashboard/laporan memicu rekomputasi data secara real-time tanpa delay berlebihan. | Filter response < 1 detik |
| NF-11 | Kinerja | Badge auto-refresh | Badge notifikasi (approval karyawan, transaksi besar) auto-refresh setiap kali dashboard dimuat tanpa perlu manual refresh. | Badge updated on every dashboard load |
| NF-12 | Kinerja | Upload foto optimal | Upload foto bukti transaksi berhasil untuk file hingga 5 MB dengan kompresi otomatis jika diperlukan. | Max upload size 5 MB, success rate > 95% |
| NF-13 | Ketersediaan | Koneksi internet | Aplikasi memerlukan koneksi internet aktif untuk sinkronisasi data dengan server Laravel; offline mode tidak didukung. | Online-only operation |
| NF-14 | Ketersediaan | Server uptime | Server Laravel backend memiliki uptime minimal 99% untuk mendukung operasional bisnis harian. | Uptime > 99% |
| NF-15 | Usabilitas | Antarmuka mobile-first | Aplikasi dirancang dengan UI mobile-first menggunakan Flutter; navigasi tab dan bottom sheet mudah dipahami dan diakses dengan satu tangan. | Mobile-optimized UI components |
| NF-16 | Usabilitas | Pesan error informatif | Sistem menampilkan pesan error yang jelas dan spesifik saat validasi gagal (mis. "Cabang sedang tutup", "Belum ada pengeluaran hari ini", "Transaksi melebihi threshold"). | Error messages dalam Bahasa Indonesia |
| NF-17 | Usabilitas | Konfirmasi aksi destruktif | Aksi penghapusan (transaksi, cabang, karyawan, kategori) selalu menampilkan dialog konfirmasi dengan konsekuensi yang jelas sebelum dieksekusi. | 100% delete actions dengan konfirmasi |
| NF-18 | Usabilitas | Format mata uang konsisten | Nominal uang ditampilkan dalam format Rupiah (Rp) dengan pemisah ribuan dan desimal 2 digit di seluruh aplikasi. | Format: Rp 1.000.000,00 |
| NF-19 | Usabilitas | Format tanggal konsisten | Tanggal ditampilkan dalam format Indonesia (DD/MM/YYYY atau DD MMM YYYY) dengan zona waktu yang benar per cabang. | Timezone-aware date display |
| NF-20 | Usabilitas | Empty state informatif | Halaman dengan data kosong menampilkan empty state dengan icon dan pesan yang sesuai konteks (bukan layar putih atau error). | Empty state untuk list kosong |
| NF-21 | Reliabilitas | Integritas data transaksi | Data transaksi tersimpan konsisten di database; relasi foreign key dijaga dengan constraint CASCADE/RESTRICT sesuai logika bisnis. | Zero data corruption incidents |
| NF-22 | Reliabilitas | Kode undangan sekali pakai | Kode undangan hanya dapat digunakan satu kali dan otomatis kadaluarsa setelah 24 jam sejak dibuat (expired_at otomatis diset). | Kode undangan tidak dapat reused |
| NF-23 | Reliabilitas | Audit trail transaksi | Setiap transaksi menyimpan user_id creator untuk pelacakan; nama creator ditampilkan sebagai created_by_name di response API. | 100% transaksi punya user_id |
| NF-24 | Reliabilitas | Safe delete cabang | Sistem menolak penghapusan cabang jika cabang memiliki transaksi aktif, Kepala Cabang aktif, atau karyawan aktif dengan pesan error yang spesifik. | Zero accidental data loss |
| NF-25 | Reliabilitas | Safe delete kategori | Sistem menolak penghapusan kategori jika masih digunakan oleh transaksi aktif dengan pesan error yang informatif. | Referential integrity maintained |
| NF-26 | Reliabilitas | Consistency check threshold | Sistem memvalidasi threshold transaksi besar > 0 dan dalam range reasonable (max 1 miliar) sebelum disimpan. | Threshold validation di backend |
| NF-27 | Reliabilitas | Foto storage cleanup | Saat transaksi dihapus, foto bukti terkait juga dihapus dari storage untuk mencegah file orphan. | Zero orphaned foto files |
| NF-28 | Skalabilitas | Multi-cabang unlimited | Sistem mendukung satu usaha dengan jumlah cabang tidak terbatas; owner dapat mengelola puluhan cabang dari satu akun. | No hard limit on cabang count |
| NF-29 | Skalabilitas | Multi-karyawan per cabang | Setiap cabang dapat memiliki banyak karyawan dan 1 Kepala Cabang; sistem mendukung ratusan karyawan per bisnis. | No hard limit on karyawan count |
| NF-30 | Skalabilitas | Transaksi historis | Sistem menyimpan semua transaksi historis tanpa batas waktu; performa query tetap optimal dengan indexing yang tepat (cabang_id, tanggal, business_id). | Query performance < 2s untuk 10K+ transaksi |
| NF-31 | Skalabilitas | Kategori fleksibel | Owner dapat membuat kategori dengan scope global (semua cabang) atau per cabang tanpa batas jumlah. | Flexible kategori management |
| NF-32 | Portabilitas | Cross-platform Flutter | Aplikasi Flutter dapat dijalankan di Android, iOS, dan Web dengan satu codebase; fitur inti berfungsi identik di semua platform. | Support Android, iOS, Web |
| NF-33 | Portabilitas | API RESTful standar | Backend Laravel menyediakan REST API dengan format JSON standar, dapat diakses dari client manapun (tidak terikat Flutter). | RESTful API design |
| NF-34 | Maintainability | Arsitektur terpisah | Frontend (Flutter) dan backend (Laravel) terpisah sepenuhnya; komunikasi hanya via REST API untuk memudahkan pengembangan dan deployment independen. | Decoupled architecture |
| NF-35 | Maintainability | Kode modular | Kode Flutter terstruktur dengan service layer (ApiService, AuthService, DomainApiService) terpisah dari UI; controller Laravel terpisah per domain. | Service-based architecture |
| NF-36 | Maintainability | Migration database | Semua perubahan skema database dilakukan via Laravel migration yang ter-versioning; rollback dapat dilakukan dengan aman. | 100% schema changes via migration |
| NF-37 | Validasi | Validasi input server-side | Semua input transaksi, master data, dan pengaturan divalidasi di sisi server sebelum disimpan ke database dengan aturan yang ketat. | Server-side validation 100% |
| NF-38 | Validasi | Validasi jam operasional | Sistem memvalidasi input transaksi karyawan berdasarkan jam operasional cabang dengan zona waktu yang benar (WIB/WITA/WIT). | Timezone-aware validation |
| NF-39 | Validasi | Validasi urutan transaksi | Sistem memvalidasi bahwa karyawan tidak dapat input pemasukan sebelum ada pengeluaran di hari yang sama (toggle validation). | Business rule enforced di backend |

---

## 5. Fitur Khusus & Business Rules

| Kode | Fitur | Deskripsi | Aktor Terkait |
|------|-------|-----------|---------------|
| BR-01 | Perbedaan role Kepala Cabang vs Karyawan | Kepala Cabang dapat input transaksi tanpa batasan jam operasional atau validasi urutan input; Karyawan dibatasi jam operasional dan harus input pengeluaran dulu sebelum pemasukan. | Kepala Cabang, Karyawan |
| BR-02 | Notifikasi transaksi mencurigakan | Owner dapat set threshold nominal transaksi besar; jika Kepala Cabang input transaksi > threshold, Owner mendapat notifikasi otomatis di badge dashboard. | Owner, Kepala Cabang |
| BR-03 | Review transaksi besar | Owner dapat melihat list transaksi yang melebihi threshold dan menandainya sebagai sudah ditinjau (is_reviewed); transaksi yang sudah ditinjau tidak muncul lagi di notifikasi. | Owner |
| BR-04 | Auto-calculate gaji karyawan | Sistem dapat menghitung gaji karyawan otomatis berdasarkan persentase dari laba bersih cabang (fitur opsional yang dapat dikonfigurasi Owner). | Owner, Karyawan |
| BR-05 | Karyawan non-login | Owner dapat menambah data karyawan yang tidak memerlukan akses login (karyawan lapangan/shift); data digunakan untuk manajemen kepegawaian tanpa akses aplikasi. | Owner |
| BR-06 | Approval workflow | User baru yang daftar via kode undangan memiliki status 'pending' dan harus di-approve oleh Owner sebelum mendapat akses penuh; badge notifikasi muncul di dashboard Owner. | Owner, Karyawan, Kepala Cabang |
| BR-07 | Dual badge notifications | Dashboard Owner menampilkan 2 jenis badge: (1) jumlah karyawan pending yang perlu approval, (2) jumlah transaksi besar yang belum ditinjau. | Owner |
| BR-08 | Zona waktu per cabang | Setiap cabang dapat memiliki zona waktu berbeda (WIB/WITA/WIT); validasi jam operasional dan display tanggal menggunakan zona waktu cabang yang benar. | Owner, Kepala Cabang, Karyawan |
| BR-09 | PDF report dengan simbol text | Export PDF laporan keuangan menggunakan simbol text dalam lingkaran (P, C, M, +, -, =, Rp, i) bukan emoji atau Material Icons untuk kompatibilitas rendering di semua platform. | Owner, Kepala Cabang |
| BR-10 | Modal kiriman flag | Transaksi dapat ditandai sebagai "modal kiriman" (checkbox) untuk membedakan dari pemasukan operasional biasa; mempengaruhi perhitungan laba bersih. | Owner, Kepala Cabang |

---

## 6. Ringkasan

| Jenis | Jumlah | Rentang Kode |
|-------|--------|--------------|
| Kebutuhan Fungsional — Owner | 46 | F-01 s/d F-46 |
| Kebutuhan Fungsional — Kepala Cabang | 18 | F-47 s/d F-64 |
| Kebutuhan Fungsional — Karyawan | 11 | F-65 s/d F-75 |
| Kebutuhan Nonfungsional | 39 | NF-01 s/d NF-39 |
| Business Rules & Fitur Khusus | 10 | BR-01 s/d BR-10 |
| **Total** | **124** | — |

---

## 7. Perubahan dari Versi 1.0 ke 2.0

### Fitur Baru:
1. **Role Kepala Cabang** — Role terpisah dari karyawan dengan hak akses lebih luas (F-47 s/d F-64)
2. **Notifikasi Transaksi Besar** — Threshold setting, badge notifikasi, dan review workflow (F-42 s/d F-45, BR-02, BR-03)
3. **Dual Badge Notifications** — Badge terpisah untuk approval karyawan dan transaksi besar (F-30, F-43, BR-07)
4. **Edit & Hapus Cabang** — Fitur edit cabang dan safe delete dengan validasi (F-16, F-17, NF-24)
5. **Foto Bukti CORS Fix** — API proxy untuk akses foto dengan autentikasi (F-08, F-09, NF-05, NF-06)
6. **Loading Indicator Konsisten** — Loading state di semua halaman (NF-09)
7. **Karyawan Non-Login** — Manajemen karyawan tanpa akses aplikasi (F-21, BR-05)
8. **Auto-Calculate Gaji** — Perhitungan gaji otomatis berdasarkan laba cabang (F-26, BR-04)
9. **Zona Waktu per Cabang** — Support multiple timezone untuk validasi jam operasional (NF-19, NF-38, BR-08)
10. **PDF Export Improvements** — Simbol text untuk kompatibilitas rendering (F-41, BR-09)

### Perbaikan Bug:
1. Filter cabang di dashboard Owner dan Laporan Keuangan kini memicu rekomputasi data dengan benar (F-05, F-39, NF-10)
2. Created by transaksi menampilkan nama user yang benar menggunakan kolom user_id (F-10, F-58, NF-23)
3. Google auto-login setelah logout diperbaiki dengan prompt 'select_account' (F-01, F-47, F-65, NF-01)
4. Validasi jam operasional menggunakan zona waktu cabang yang benar (F-70, F-71, NF-38)
5. Validasi urutan input transaksi karyawan diperbaiki (F-69, F-72, NF-39)

### Peningkatan Keamanan:
1. Foto bukti hanya dapat diakses dengan autentikasi token (NF-05)
2. CORS handling yang benar untuk Flutter Web (NF-06)
3. Logout membersihkan sesi Google dengan benar (F-02, NF-07)
4. Isolasi data per bisnis/cabang lebih ketat (NF-04)

### Peningkatan UX:
1. Loading indicator konsisten di semua halaman (NF-09)
2. Pesan error lebih informatif dan spesifik (NF-16)
3. Empty state untuk halaman dengan data kosong (NF-20)
4. Konfirmasi untuk aksi destruktif (NF-17)
5. Badge auto-refresh untuk notifikasi real-time (NF-11)

---

**Catatan:** Dokumen ini mencerminkan state aplikasi KASENTRA versi 2.0 setelah implementasi semua fitur baru dan perbaikan bug yang telah dilakukan.
