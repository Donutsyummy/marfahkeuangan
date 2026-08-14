# MARFAH KEUANGAN — APPLE-STYLE UI/UX REDESIGN

## ROLE

Kamu adalah **Senior Frontend Engineer + UI/UX Designer** yang berpengalaman membuat aplikasi fintech modern dengan kualitas visual setara produk Apple.

Saya memiliki website keuangan bernama **Marfah Keuangan**.

Website:
https://marfah-keuangan.vercel.app/

Tugas utama kamu adalah melakukan **REDESIGN UI/UX** website tersebut agar terlihat jauh lebih modern, premium, clean, dan profesional dengan inspirasi desain **Apple / iOS / Apple Finance**, tetapi tetap mempertahankan seluruh sistem yang sudah ada.

---

# ⚠️ ATURAN PALING PENTING

## JANGAN MENGHAPUS FITUR YANG SUDAH ADA

Sebelum melakukan perubahan:

1. Inspect seluruh project.
2. Pahami struktur folder.
3. Pahami semua halaman.
4. Pahami semua komponen.
5. Pahami database.
6. Pahami API.
7. Pahami authentication.
8. Pahami state management.
9. Pahami semua kategori laporan.
10. Pahami semua fitur CRUD.
11. Pahami semua filter dan pencarian.
12. Pahami semua grafik/statistik.

### Jangan menghapus:

- kategori laporan
- kategori pemasukan
- kategori pengeluaran
- transaksi
- laporan
- dashboard
- statistik
- grafik
- filter
- pencarian
- login
- register
- user profile
- database
- API
- fitur tambah data
- fitur edit data
- fitur hapus data
- export data
- pagination
- notification
- settings
- fitur administrasi
- permission/role
- validasi
- business logic

**Jika sebuah fitur sudah ada, fitur tersebut HARUS tetap tersedia setelah redesign.**

Jika ada kategori laporan yang sudah ada, **jangan mengganti nama, menghapus, menggabungkan, atau menyembunyikannya.**

Redesign hanya mengubah:

- visual
- layout
- typography
- spacing
- warna
- card
- navigation
- animation
- responsive behavior
- UX

Business logic harus tetap bekerja.

---

# 1. DESIGN DIRECTION

Gunakan prinsip desain Apple:

- minimal
- clean
- premium
- elegant
- spacious
- modern
- subtle
- professional
- intuitive

Jangan membuat desain seperti:

- dashboard admin template biasa
- crypto dashboard
- neon fintech
- website penuh gradient
- UI terlalu ramai
- terlalu banyak border
- terlalu banyak shadow
- terlalu banyak card

Target visual:

> "Kalau Apple membuat aplikasi manajemen keuangan modern, kira-kira tampilannya seperti ini."

---

# 2. COLOR SYSTEM

## Light Mode

Gunakan:

- #F5F5F7
- white
- soft gray

Text:

- hampir hitam
- secondary text abu-abu

Primary:

- gunakan warna brand Marfah yang sudah ada jika tersedia.

Jangan mengganti identitas brand secara sembarangan.

## Dark Mode

Sediakan dark mode jika struktur aplikasi memungkinkan.

Gunakan:

- #000000
- #111111
- #1C1C1E
- #2C2C2E

Jangan menggunakan pure black untuk semua elemen.

---

# 3. TYPOGRAPHY

Gunakan typography modern ala Apple.

Prioritas:

1. SF Pro jika tersedia
2. Inter
3. system-ui
4. -apple-system

Gunakan hierarchy yang jelas.

Contoh:

Dashboard title:

32–48px

Section title:

20–26px

Body:

14–17px

Secondary text:

12–14px

Angka saldo:

36–56px

Angka keuangan harus menjadi salah satu elemen visual utama.

---

# 4. DASHBOARD

Redesign dashboard menjadi fokus utama aplikasi.

Bagian atas:

MARFAH

Financial Dashboard

Kemudian:

## TOTAL SALDO

Tampilkan:

Rp XX.XXX.XXX

Dengan informasi:

+X.X% bulan ini

Gunakan visual yang sangat clean.

Jangan membuat card terlalu besar.

---

# 5. FINANCIAL SUMMARY

Buat summary yang mudah dibaca.

Contoh:

Pemasukan

Rp XX.XXX.XXX

Pengeluaran

Rp XX.XXX.XXX

Tabungan

Rp XX.XXX.XXX

Saldo

Rp XX.XXX.XXX

Gunakan layout responsive.

Desktop:

4 kolom

Tablet:

2 kolom

Mobile:

1–2 kolom

---

# 6. LAPORAN — WAJIB DIPERTAHANKAN

Ini sangat penting.

**SEMUA KATEGORI LAPORAN YANG SUDAH ADA HARUS TETAP ADA.**

Jangan mengurangi jumlah kategori.

Jika sekarang terdapat:

- laporan harian
- laporan mingguan
- laporan bulanan
- laporan tahunan
- kategori pemasukan
- kategori pengeluaran
- laporan berdasarkan kategori
- statistik lainnya

maka semuanya harus tetap tersedia.

Jika terdapat kategori lain yang ditemukan ketika melakukan audit project, pertahankan juga.

### Redesign halaman laporan

Buat layout seperti aplikasi finansial premium.

Bagian atas:

Laporan Keuangan

Kemudian:

Period selector

Hari | Minggu | Bulan | Tahun

Tetap pertahankan seluruh pilihan yang tersedia sebelumnya.

---

# 7. CHART

Upgrade visualisasi grafik tanpa mengubah data.

Gunakan:

- smooth line chart
- clean bar chart
- donut chart jika memang sesuai
- tooltip modern
- subtle animation

Jangan membuat grafik terlalu berwarna.

Gunakan warna seperlunya untuk membedakan:

- Pemasukan
- Pengeluaran
- Saldo
- Kategori

---

# 8. TRANSACTION LIST

Redesign transaksi seperti Apple Wallet / iOS activity list.

Contoh struktur:

ICON

Nama transaksi

Kategori

Tanggal

                    - Rp125.000

Gunakan grouping berdasarkan:

- Today
- Yesterday
- This Week
- This Month

Jika fitur grouping belum ada, boleh dibuat selama tidak mengubah data asli.

---

# 9. ADD TRANSACTION

Form tambah transaksi harus sangat mudah digunakan.

Gunakan modal/sheet modern.

Field:

- tipe transaksi
- nominal
- kategori
- tanggal
- catatan
- metode pembayaran
- field lain yang memang sudah tersedia

**Jangan menghilangkan field existing.**

Gunakan:

- large input
- rounded corners
- clear labels
- validation
- keyboard-friendly mobile input

---

# 10. MOBILE UI

Mobile harus menjadi prioritas.

Pastikan:

- responsive
- touch-friendly
- tidak ada horizontal overflow
- tombol mudah ditekan
- input nyaman
- grafik tidak rusak
- tabel tidak keluar layar

Gunakan bottom navigation jika sesuai dengan struktur aplikasi.

Contoh:

Home

Laporan

Transaksi

Tambah

Profile

Tetapi jangan menghapus navigasi desktop yang sudah ada.

---

# 11. NAVIGATION

Buat navigation yang terasa seperti aplikasi premium.

Desktop:

Sidebar minimal.

Mobile:

Bottom navigation.

Navigation harus memiliki:

- icon
- label
- active state
- smooth transition

Jangan menggunakan sidebar yang terlalu besar.

---

# 12. MICRO INTERACTIONS

Tambahkan animasi yang halus.

Contoh:

- fade in
- slide
- scale kecil
- hover
- button feedback
- modal animation
- tab transition
- chart animation
- number transition

Gunakan durasi sekitar:

150–300ms

Jangan menggunakan animasi berlebihan.

Target:

**smooth, bukan flashy.**

---

# 13. GLASSMORPHISM

Gunakan glass effect secara terbatas.

Contoh:

- navigation
- modal
- floating action button
- beberapa summary component

Jangan membuat seluruh website transparan.

Gunakan:

- backdrop blur
- subtle border
- soft shadow

---

# 14. CARD DESIGN

Card harus:

- rounded
- clean
- subtle
- tidak terlalu banyak shadow

Gunakan radius sekitar:

16–28px

Hindari:

card bertumpuk di dalam card bertumpuk.

---

# 15. EMPTY STATE

Jika tidak ada transaksi/data:

Jangan tampilkan halaman kosong.

Buat empty state:

icon sederhana

judul

deskripsi

CTA

Contoh:

Belum ada transaksi

Mulai catat transaksi pertamamu untuk melihat perkembangan keuangan.

[Tambah Transaksi]

---

# 16. LOADING STATE

Gunakan skeleton loading modern.

Jangan menggunakan loading spinner di seluruh halaman jika skeleton lebih cocok.

---

# 17. ERROR STATE

Buat error state yang clean.

Contoh:

Something went wrong

Coba lagi beberapa saat kemudian.

[Try Again]

Tetap gunakan bahasa utama aplikasi.

---

# 18. ACCESSIBILITY

Pastikan:

- contrast bagus
- keyboard navigation
- focus state
- aria-label
- button memiliki label
- form memiliki label
- warna bukan satu-satunya indikator status

---

# 19. PERFORMANCE

Jangan membuat redesign menyebabkan website lebih berat.

Prioritaskan:

- lazy loading
- code splitting jika relevan
- optimasi gambar
- minimalkan dependency baru
- jangan menambahkan library besar jika tidak diperlukan

---

# 20. DATA & BACKEND

Ini WAJIB.

Jangan mengubah:

- schema database
- nama tabel
- API contract
- authentication flow
- database query
- business logic

kecuali benar-benar diperlukan untuk memperbaiki bug.

Jika membutuhkan perubahan backend:

**jelaskan terlebih dahulu sebelum mengubahnya.**

---

# 21. EXISTING FEATURES AUDIT

Sebelum coding, lakukan audit.

Buat daftar internal:

### Pages

- semua halaman yang ditemukan

### Components

- semua component penting

### Features

- semua fitur

### Reports

- semua kategori laporan

### Database

- semua tabel

### API

- semua endpoint

### Authentication

- semua flow login/logout/session

Tujuan audit:

**Tidak boleh ada fitur yang hilang setelah redesign.**

---

# 22. DESIGN SYSTEM

Buat design system konsisten.

Gunakan:

### Border radius

8px
12px
16px
24px
32px

### Spacing

4
8
12
16
24
32
48
64

### Typography

Display

Heading

Body

Caption

### Components

Button

Input

Select

Modal

Card

Badge

Tabs

Dropdown

Toast

Table

Chart

Navigation

---

# 23. APPLE-STYLE DETAILS

Tambahkan detail premium:

- large typography
- whitespace
- subtle shadows
- translucent navigation
- smooth scrolling
- sticky header
- elegant modal
- rounded buttons
- subtle separators
- clean icons
- smooth number transitions
- responsive layout

Tetapi jangan menyalin desain Apple secara literal.

Buat:

**Apple-inspired, bukan Apple clone.**

---

# 24. BRAND MARFAH

Nama:

**Marfah**

Gunakan branding yang sudah ada.

Jangan mengganti logo/warna brand secara sembarangan.

Jika logo sudah tersedia:

pertahankan.

Jika belum:

buat treatment typographic sederhana.

---

# 25. RESPONSIVE BREAKPOINT

Pastikan minimal:

Mobile:

320px+

Tablet:

768px+

Desktop:

1024px+

Large desktop:

1440px+

Tidak boleh ada layout yang rusak.

---

# 26. IMPLEMENTATION PROCESS

Ikuti proses:

### STEP 1

Inspect seluruh repository.

### STEP 2

Jalankan project.

### STEP 3

Identifikasi framework.

### STEP 4

Identifikasi semua halaman.

### STEP 5

Identifikasi semua fitur.

### STEP 6

Identifikasi seluruh kategori laporan.

### STEP 7

Identifikasi database/API.

### STEP 8

Buat design system.

### STEP 9

Redesign dashboard.

### STEP 10

Redesign laporan.

### STEP 11

Redesign transaksi.

### STEP 12

Redesign forms.

### STEP 13

Redesign navigation.

### STEP 14

Responsive optimization.

### STEP 15

Accessibility.

### STEP 16

Performance optimization.

### STEP 17

Test seluruh fitur.

---

# 27. REGRESSION TEST

Setelah redesign selesai, pastikan:

- login masih bekerja
- logout masih bekerja
- tambah transaksi masih bekerja
- edit transaksi masih bekerja
- hapus transaksi masih bekerja
- kategori tetap muncul
- laporan tetap muncul
- filter tetap bekerja
- search tetap bekerja
- grafik tetap bekerja
- database tetap menyimpan data
- data lama tetap muncul
- mobile responsive
- desktop responsive

**Jangan hanya mengecek tampilan.**

Pastikan functionality tetap bekerja.

---

# 28. FINAL QUALITY TARGET

Website akhir harus terasa seperti:

**"Apple Finance Dashboard × Modern Fintech × Marfah"**

Bukan seperti:

"Admin Dashboard Template".

Prioritaskan:

1. usability
2. readability
3. hierarchy
4. consistency
5. responsiveness
6. performance
7. aesthetics

---

# FINAL INSTRUCTION

Mulai dengan **menganalisis project yang sudah ada terlebih dahulu**.

Jangan langsung menghapus atau rewrite seluruh project.

Pertahankan arsitektur yang masih bagus.

Lakukan perubahan secara incremental.

Jika menemukan fitur yang tidak jelas, **pertahankan fitur tersebut daripada menghapusnya.**

Jika ada konflik antara desain baru dan functionality lama:

**FUNCTIONALITY LAMA MENANG.**

Tujuan akhirnya:

> Membuat Marfah Keuangan terlihat seperti aplikasi finansial premium dengan kualitas visual Apple, sambil mempertahankan 100% kategori laporan, data, fitur, dan business logic yang sudah ada.
