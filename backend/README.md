# Backend API - Koleksi Punya Rini Rashifah

Backend REST API untuk aplikasi manajemen lemari digital dan pelacakan koleksi pribadi Rini Rashifah. Dibuat menggunakan Golang dengan framework Gin, database PostgreSQL (kompatibel dengan Neon), dan penyimpanan gambar Cloudinary.

## Fitur Utama

- **Authentication & Security:** Akses terproteksi menggunakan personal API Key (`X-API-Key`).
- **Penyimpanan Gambar Cloudinary:** Upload foto langsung ke Cloudinary (dengan fallback penyimpanan lokal otomatis untuk testing).
- **Hierarchical Storage Location:** Struktur bertingkat (Rumah -> Ruangan -> Furnitur -> Bagian Penyimpanan -> Posisi Spesifik) dengan breadcrumb dan pelacakan item di setiap level.
- **Workflow Laundry Terintegrasi:**
  - `Available` -> `In Use` -> `In Laundry` -> `Ready to Store` -> `Available`
  - Pencatatan siklus laundry otomatis ke `laundry_history`.
  - Pencatatan perpindahan lokasi otomatis ke `location_history`.
- **Dashboard Ringkasan:** Ringkasan status ketersediaan, peringatan cucian, dan barang terbaru.

---

## Daftar Endpoint REST API

Semua endpoint dilindungi header:
```
X-API-Key: rini-secret-2024
```
(Atau `Authorization: Bearer rini-secret-2024`)

### 1. Health Check (Public)
- `GET /health` : Cek status kesehatan server

### 2. Dashboard
- `GET /api/v1/dashboard` : Ringkasan jumlah barang per status, barang sedang dicuci, barang selesai cuci belum disimpan, dan barang terbaru.

### 3. Collection Items
- `GET /api/v1/items` : Ambil daftar barang. Query params:
  - `search` (pencarian nama, merek, warna, catatan)
  - `category_id` (filter ID kategori)
  - `status` (Available, In Use, In Laundry, Ready to Store, Unavailable)
  - `location_id` (filter lokasi penyimpanan)
  - `color`, `brand`
- `GET /api/v1/items/:id` : Detail lengkap barang, termasuk riwayat lokasi dan laundry.
- `POST /api/v1/items` : Tambah barang baru.
- `PUT /api/v1/items/:id` : Update barang (mencatat riwayat lokasi jika lokasi berubah).
- `DELETE /api/v1/items/:id` : Hapus barang beserta riwayatnya.

### 4. Status & Laundry Workflow
- `PATCH /api/v1/items/:id/status` : Ubah status ketersediaan secara manual.
- `POST /api/v1/items/:id/laundry` : Masukkan barang ke laundry (status `In Laundry`, catat waktu mulai & lokasi keranjang cucian).
- `PATCH /api/v1/items/:id/laundry/complete` : Tandai cucian selesai (status `Ready to Store`, catat waktu selesai & lokasi jemuran/setrika).
- `POST /api/v1/items/:id/store` : Simpan barang kembali (status `Available`, pilih lokasi penyimpanan utama).
- `POST /api/v1/items/:id/move` : Pindahkan barang ke lokasi lain dan catat riwayat perpindahan.

### 5. Riwayat (History)
- `GET /api/v1/items/:id/location-history` : Riwayat perpindahan lokasi barang.
- `GET /api/v1/items/:id/laundry-history` : Riwayat seluruh siklus pencucian barang.

### 6. Storage Locations
- `GET /api/v1/locations` : Daftar seluruh lokasi penyimpanan beserta jumlah item di dalamnya.
- `GET /api/v1/locations/tree` : Struktur pohon hierarki lokasi bertingkat.
- `GET /api/v1/locations/:id` : Detail lokasi beserta breadcrumb dan sub-lokasi.
- `GET /api/v1/locations/:id/items` : Daftar barang yang tersimpan di lokasi ini.
- `POST /api/v1/locations` : Tambah lokasi baru (bisa menyertakan `parent_location_id`).
- `PUT /api/v1/locations/:id` : Perbarui nama/tipe/deskripsi lokasi.
- `DELETE /api/v1/locations/:id` : Hapus lokasi (dicegah jika masih ada barang atau sub-lokasi).

### 7. Categories
- `GET /api/v1/categories` : Daftar kategori dan jumlah barangnya.
- `POST /api/v1/categories` : Tambah kategori baru.
- `PUT /api/v1/categories/:id` : Perbarui nama kategori.
- `DELETE /api/v1/categories/:id` : Hapus kategori (dicegah jika masih digunakan barang).

### 8. Upload Foto
- `POST /api/v1/upload` : Upload gambar (`multipart/form-data`, form key: `image`). Mengembalikan URL publik.

### 9. Sample Data Seeder
- `POST /api/v1/seed-sample-data` : Mengisi database dengan contoh koleksi pakaian Rini jika kosong.

---

## Menjalankan Secara Lokal

```bash
cd backend
go run ./cmd/api
```
Server akan berjalan di `http://localhost:8080`.
Jika `DATABASE_URL` tidak diisi, backend otomatis menggunakan SQLite lokal (`collection_rini.db`).

---

## Panduan Deployment ke Render & Neon

1. **Database Neon:**
   - Buat project baru di [Neon Console](https://console.neon.tech).
   - Salin connection string PostgreSQL, contoh:
     `postgres://user:password@ep-xyz-pooler.ap-southeast-1.aws.neon.tech/neondb?sslmode=require`

2. **Render Web Service:**
   - Hubungkan repository GitHub ke Render.
   - Buat **New Web Service** -> pilih repo ini.
   - Pilih environment **Docker**.
   - Set **Docker Command / Context**: Root directory `backend` atau sesuaikan `backend/Dockerfile`.
   - Masukkan Environment Variables:
     - `PORT`: `8080`
     - `GIN_MODE`: `release`
     - `API_KEY`: `[Kata Sandi Pribadi Pilihan Rini]`
     - `DATABASE_URL`: `[Connection String Neon PostgreSQL]`
     - `CLOUDINARY_CLOUD_NAME`: `[Cloud Name Cloudinary]`
     - `CLOUDINARY_API_KEY`: `[API Key Cloudinary]`
     - `CLOUDINARY_API_SECRET`: `[API Secret Cloudinary]`
   - Deploy! Render akan otomatis membangun container dan menjalankan backend dengan SSL/HTTPS gratis.
