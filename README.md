# Koleksi Punya Rini Rashifah 🌸
### *Personal Collection & Storage Management Mobile App*

Aplikasi mobile pribadi berbasis Android untuk mencatat seluruh koleksi fashion dan barang pribadi milik Rini Rashifah, mengetahui lokasi penyimpanannya secara spesifik, serta memantau status ketersediaan dan siklus pencucian (laundry) secara real-time.

---

## 📑 Daftar Isi
1. [Latar Belakang & Pertanyaan Kunci](#-latar-belakang--pertanyaan-kunci)
2. [Arsitektur & Tech Stack](#-arsitektur--tech-stack)
3. [Fitur Utama Aplikasi](#-fitur-utama-aplikasi)
4. [Desain & Identitas Visual](#-desain--identitas-visual)
5. [Skema Database & Migrasi PostgreSQL](#-skema-database--migrasi-postgresql)
6. [Dokumentasi REST API](#-dokumentasi-rest-api)
7. [Panduan Menjalankan Secara Lokal (Development)](#-panduan-menjalankan-secara-lokal-development)
8. [Panduan Deployment Online (Render, Neon, Cloudinary)](#-panduan-deployment-online-render-neon-cloudinary)
9. [Panduan Build APK Android](#-panduan-build-apk-android)
10. [Struktur Folder Proyek](#-struktur-folder-proyek)

---

## 💡 Latar Belakang & Pertanyaan Kunci

Aplikasi berfungsi sebagai **lemari digital pribadi** yang menjawab 3 pertanyaan utama pemilik:
1. **Barang ini disimpan di mana?** 
   - Dilacak melalui struktur bertingkat (*Rumah → Ruangan → Furnitur → Bagian Penyimpanan → Posisi Spesifik*).
2. **Apakah barang ini tersedia dan siap digunakan?**
   - Dilacak lewat status ketersediaan (*Available, In Use, In Laundry, Ready to Store, Unavailable*).
3. **Apakah barang ini sedang dicuci atau sudah selesai dicuci?**
   - Dilacak melalui modul khusus Laundry dengan pencatatan siklus otomatis (*Laundry Tracking*).

---

## 🛠️ Arsitektur & Tech Stack

| Komponen | Teknologi | Keterangan |
| :--- | :--- | :--- |
| **Frontend** | Flutter 3 (Dart) | UI modern, Provider state management, CachedNetworkImage, Google Fonts |
| **Backend** | Golang (Gin Framework) | REST API berkinerja tinggi, GORM ORM, modular handlers |
| **Database** | PostgreSQL (Neon Cloud) | Serverless PostgreSQL di Neon dengan fallback SQLite lokal saat offline |
| **Image Storage** | Cloudinary CDN | Penyimpanan foto di cloud dengan fallback penyimpanan lokal `/uploads` |
| **Hosting Backend** | Render | Cloud Web Service dengan Docker container |
| **Keamanan** | API Key Header (`X-API-Key`) | Akses privat personal untuk melindungi data Rini |

---

## 📱 Fitur Utama Aplikasi

### 1. Dashboard (Home)
- Sapaan hangat *"Welcome to Rini's Collection ✨"*.
- Kolom pencarian cepat barang.
- Ringkasan status ketersediaan (*Available, In Use, In Laundry, Ready to Store, Unavailable*).
- Peringatan cucian aktif (*Barang yang sedang dicuci & barang selesai dicuci belum disimpan*).
- Daftar koleksi barang yang baru ditambahkan/diperbarui dengan tombol aksi cepat.

### 2. My Collection (Galeri Koleksi)
- Tampilan galeri foto dengan kartu estetik ber-shadow lembut.
- Kategori bawaan: *Tops, Bottoms, Dresses & Outfits, Hijab, Shoes, Sandals, Bags, Accessories, Beauty & Personal Care, Others*.
- Fitur **Tambah Kategori Baru** langsung dari aplikasi.
- Filter cepat status dan kategori horizontal (chips).

### 3. Add & Edit Item (Formulir Barang)
- Input: Nama barang (wajib), Foto (Kamera / Galeri), Kategori (wajib), Warna, Merek, Ukuran, Lokasi Penyimpanan, Detail Posisi Spesifik, Status Ketersediaan, dan Catatan.
- Otomatis kompres dan upload gambar ke Cloudinary / local fallback.

### 4. Storage Location Explorer & Management
- Struktur hierarki bertingkat:
  - **Rumah** *(e.g. Rumah Rini)*
    - **Ruangan** *(e.g. Kamar Tidur, Area Laundry)*
      - **Furnitur** *(e.g. Lemari Pakaian, Rak Sepatu, Meja Rias)*
        - **Bagian Penyimpanan** *(e.g. Gantungan Kiri, Laci 1, Laci 2)*
          - **Posisi Spesifik** *(e.g. Rak 2, Sisi Depan, Kotak Aksesori Pink)*
- Navigasi breadcrumb interaktif.
- Tambah lokasi dan sub-lokasi baru kapan saja.
- Menampilkan barang yang ada di dalam lokasi yang sedang dipilih.
- Pencegahan penghapusan lokasi jika masih ada barang di dalamnya (*Foreign Key RESTRICT*).

### 5. Availability Status & Laundry Tracking
- Alur Status:
  $$\text{Available} \longrightarrow \text{In Use} \longrightarrow \text{In Laundry} \longrightarrow \text{Ready to Store} \longrightarrow \text{Available}$$
- **Kirim ke Laundry:** Menandai barang `In Laundry`, mencatat waktu mulai, dan memindahkan ke keranjang cucian.
- **Selesai Dicuci:** Menandai barang `Ready to Store`, mencatat waktu penyelesaian, dan memindahkan ke area jemuran/meja setrika.
- **Simpan & Tandai Available:** Menandai barang `Available` dan memilih lokasi lemari tempat barang disimpan kembali.

### 6. Riwayat Lengkap (Location & Laundry History)
- Riwayat perpindahan lokasi fisik (*Location History*): Dari mana, ke mana, kapan, dan catatan pemindahan.
- Riwayat siklus pencucian (*Laundry History*): Jam mulai dicuci, jam selesai dicuci, dan catatan deterjen/perawatan.

### 7. Settings (Pengaturan)
- Konfigurasi URL backend Render online dan API Key personal.
- Indikator status koneksi (Terhubung ✨ / Gagal).
- Tombol **"Isi Data Contoh" (Seeder)** untuk memasukkan 5 busana awal secara instan.
- Sinkronisasi ulang data.

---

## 🎨 Desain & Identitas Visual

- **Palet Warna Feminin & Estetik:**
  - *Dusty Rose (`#D67B8E`)*: Aksen primer dan tombol utama
  - *Blush Pink (`#FBECEF`)*: Background kartu highlight & container
  - *Cream White (`#FAF7F5`)*: Background aplikasi
  - *Dark Brown (`#382A2C`)*: Tipografi utama yang lembut dan kontras
  - *Rose Gold (`#E6A5A1`)*: Border dan aksen sekunder
- **Tipografi:** Google Fonts *Playfair Display* (Heading klasik feminin) dan *Poppins* (Body text yang bersih dan mudah dibaca).
- **Komponen:** Kartu sudut melengkung (*rounded 20px*), soft shadow, dan navigasi bottom bar 5 tab yang nyaman digunakan dengan satu tangan.

---

## 🗄️ Skema Database & Migrasi PostgreSQL

File migrasi database tersedia di [`backend/migrations/000001_init_schema.up.sql`](file:///c:/Users/User/Documents/collectionrini/backend/migrations/000001_init_schema.up.sql).

### Diagram Relasi Entitas (ERD)

```mermaid
erDiagram
    CATEGORIES ||--o{ COLLECTION_ITEMS : "has"
    STORAGE_LOCATIONS ||--o{ STORAGE_LOCATIONS : "parent of"
    STORAGE_LOCATIONS ||--o{ COLLECTION_ITEMS : "stores"
    COLLECTION_ITEMS ||--o{ LOCATION_HISTORY : "tracks"
    COLLECTION_ITEMS ||--o{ LAUNDRY_HISTORY : "tracks"
    STORAGE_LOCATIONS ||--o{ LOCATION_HISTORY : "previous/new"

    CATEGORIES {
        varchar id PK
        varchar name
        timestamptz created_at
    }

    STORAGE_LOCATIONS {
        varchar id PK
        varchar name
        varchar parent_location_id FK
        varchar location_type
        text description
        timestamptz created_at
        timestamptz updated_at
    }

    COLLECTION_ITEMS {
        varchar id PK
        varchar name
        varchar category_id FK
        text image_url
        varchar color
        varchar brand
        varchar size
        varchar current_location_id FK
        text position_detail
        varchar availability_status
        text notes
        timestamptz created_at
        timestamptz updated_at
    }

    LOCATION_HISTORY {
        varchar id PK
        varchar item_id FK
        varchar previous_location_id FK
        varchar new_location_id FK
        timestamptz moved_at
        text notes
    }

    LAUNDRY_HISTORY {
        varchar id PK
        varchar item_id FK
        timestamptz started_at
        timestamptz completed_at
        text notes
        timestamptz created_at
    }
```

---

## 📡 Dokumentasi REST API

Seluruh endpoint privat membutuhkan header:
```http
X-API-Key: rini-secret-2024
```

### Ringkasan Endpoint

| Method | Endpoint | Deskripsi |
| :--- | :--- | :--- |
| `GET` | `/health` | Health check publik status server |
| `GET` | `/api/v1/dashboard` | Statistik barang, status cucian, dan barang terbaru |
| `POST` | `/api/v1/upload` | Upload gambar (form key: `image`), return URL |
| `GET` | `/api/v1/items` | Daftar barang (filter: `search`, `category_id`, `status`, `location_id`) |
| `GET` | `/api/v1/items/:id` | Detail barang beserta riwayat lokasi & laundry |
| `POST` | `/api/v1/items` | Tambah barang baru |
| `PUT` | `/api/v1/items/:id` | Edit detail barang |
| `DELETE` | `/api/v1/items/:id` | Hapus barang |
| `PATCH` | `/api/v1/items/:id/status` | Ubah status barang secara manual |
| `POST` | `/api/v1/items/:id/laundry` | Masukkan barang ke siklus laundry |
| `PATCH` | `/api/v1/items/:id/laundry/complete` | Selesaikan pencucian (status Ready to Store) |
| `POST` | `/api/v1/items/:id/store` | Simpan kembali barang ke lemari (status Available) |
| `POST` | `/api/v1/items/:id/move` | Pindahkan lokasi fisik barang |
| `GET` | `/api/v1/items/:id/location-history` | Riwayat perpindahan lokasi barang |
| `GET` | `/api/v1/items/:id/laundry-history` | Riwayat seluruh siklus laundry barang |
| `GET` | `/api/v1/locations` | Daftar seluruh lokasi penyimpanan |
| `GET` | `/api/v1/locations/tree` | Struktur pohon hierarki lokasi bertingkat |
| `GET` | `/api/v1/locations/:id` | Detail lokasi dan breadcrumb |
| `GET` | `/api/v1/locations/:id/items` | Daftar barang di suatu lokasi |
| `POST` | `/api/v1/locations` | Tambah lokasi / sub-lokasi baru |
| `PUT` | `/api/v1/locations/:id` | Edit nama/tipe lokasi |
| `DELETE` | `/api/v1/locations/:id` | Hapus lokasi (hanya jika kosong) |
| `GET` | `/api/v1/categories` | Daftar kategori |
| `POST` | `/api/v1/categories` | Tambah kategori baru |
| `POST` | `/api/v1/seed-sample-data` | Seeder data pakaian & lokasi contoh |

---

## 💻 Panduan Menjalankan Secara Lokal (Development)

### 1. Menjalankan Backend Golang

```bash
cd backend

# Salin konfigurasi env contoh jika ingin mengubah port/key
cp .env.example .env

# Jalankan backend (akan menggunakan SQLite lokal collection_rini.db jika DATABASE_URL kosong)
go run ./cmd/api
```
Server berjalan di `http://localhost:8080`.

### 2. Menjalankan Frontend Flutter

```bash
# Pastikan dependencies terpasang
flutter pub get

# Jalankan di emulator Android atau perangkat HP via USB Debugging
flutter run
```

> **Catatan Pengujian di Emulator Android:**
> Host `10.0.2.2` pada emulator Android mengarah ke `localhost` komputer. Flutter sudah otomatis disiapkan dengan default URL `http://10.0.2.2:8080`.

---

## ☁️ Panduan Deployment Online (Render, Neon, Cloudinary)

Aplikasi dirancang agar **bisa digunakan dari HP Rini kapan saja tanpa perlu menyalakan komputer development**.

### 1. Buat Database PostgreSQL di Neon
1. Buka [Neon Console](https://console.neon.tech) dan buat project baru (bebas biaya).
2. Salin *Connection String* PostgreSQL yang diberikan, contoh:
   ```env
   DATABASE_URL=postgres://rini_owner:password@ep-sample-pooler.ap-southeast-1.aws.neon.tech/neondb?sslmode=require
   ```
3. Backend Golang menggunakan GORM AutoMigrate, sehingga tabel akan terbuat otomatis saat pertama kali tersambung. Anda juga dapat menjalankan file [`000001_init_schema.up.sql`](file:///c:/Users/User/Documents/collectionrini/backend/migrations/000001_init_schema.up.sql) di Neon SQL Editor.

### 2. Buat Akun Cloudinary (Penyimpanan Foto)
1. Buka [Cloudinary](https://cloudinary.com) dan buat akun gratis.
2. Dari Dashboard Cloudinary, salin:
   - `Cloud Name`
   - `API Key`
   - `API Secret`

### 3. Deploy Backend ke Render
1. Push repository ini ke akun **GitHub**.
2. Masuk ke [Render Dashboard](https://dashboard.render.com).
3. Klik **New +** → **Web Service**.
4. Hubungkan repository GitHub ini.
5. Konfigurasikan:
   - **Name:** `koleksi-rini-api`
   - **Root Directory:** `backend`
   - **Environment:** `Docker`
   - **Plan:** Free
6. Masukkan **Environment Variables**:
   ```env
   PORT=8080
   GIN_MODE=release
   API_KEY=rini-secret-2024
   DATABASE_URL=postgres://rini_owner:password@ep-sample-pooler.ap-southeast-1.aws.neon.tech/neondb?sslmode=require
   CLOUDINARY_CLOUD_NAME=nama_cloud_kamu
   CLOUDINARY_API_KEY=api_key_kamu
   CLOUDINARY_API_SECRET=api_secret_kamu
   CLOUDINARY_FOLDER=koleksi_rini
   ```
7. Klik **Deploy Web Service**.
8. Setelah status `Live`, salin URL Web Service Anda, contoh: `https://koleksi-rini-api.onrender.com`.

---

## 📦 Panduan Build APK Android

Setelah backend Render online:

1. Buka file [`lib/services/storage_service.dart`](file:///c:/Users/User/Documents/collectionrini/lib/services/storage_service.dart) dan ubah `defaultBaseUrl` ke URL Render Anda:
   ```dart
   static const String defaultBaseUrl = 'https://koleksi-rini-api.onrender.com';
   ```
   *(Atau pengguna cukup mengubahnya langsung melalui menu **Settings** di dalam aplikasi).*

2. Jalankan build APK rilis:
   ```bash
   flutter build apk --release
   ```
3. Berkas APK siap diinstal pada HP Rini:
   ```
   build/app/outputs/flutter-apk/app-release.apk
   ```
4. Kirim berkas APK ke HP (via WhatsApp, Google Drive, atau kabel USB) dan pasang di Android.

---

## 📁 Struktur Folder Proyek

```
collectionrini/
├── android/                   # Konfigurasi native Android & permission
├── backend/                   # Backend Golang (Framework Gin)
│   ├── cmd/api/main.go        # Entry point server backend
│   ├── config/config.go       # Konfigurasi environment & secret
│   ├── database/db.go         # Koneksi DB GORM & default seeder
│   ├── handlers/              # Controller REST API (Items, Laundry, Locations, dsb.)
│   ├── middleware/auth.go     # Proteksi API Key personal
│   ├── migrations/            # Skema SQL PostgreSQL Neon
│   ├── models/models.go       # Model data & validasi
│   ├── Dockerfile             # Multi-stage Docker build untuk Render
│   └── render.yaml            # Render Blueprint deployment
├── lib/                       # Frontend Flutter (Dart)
│   ├── main.dart              # Entry point aplikasi & Provider root
│   ├── models/                # Model Dart (Item, Location, History, Category)
│   ├── providers/             # State Management (Collection, Laundry, Location, Settings)
│   ├── screens/               # Halaman UI
│   │   ├── main_screen.dart   # Bottom navigation shell 5 tab
│   │   ├── home_screen.dart   # Dashboard & Quick Access
│   │   ├── collection_screen.dart # Galeri koleksi & filter
│   │   ├── locations_screen.dart  # Location Explorer bertingkat
│   │   ├── laundry_screen.dart    # Laundry Tracking tabs & actions
│   │   ├── item_detail_screen.dart# Detail lengkap, aksi & riwayat
│   │   ├── add_edit_item_screen.dart # Formulir tambah/edit barang
│   │   └── settings_screen.dart   # Pengaturan server, seeder, & sync
│   ├── services/              # HTTP client API & Local Storage
│   ├── theme/                 # Palet warna estetik & typography Playfair/Poppins
│   └── widgets/               # Komponen UI reusable (ItemCard, StatusBadge, dsb.)
├── pubspec.yaml               # Dependensi Flutter
└── README.md                  # Dokumentasi lengkap proyek
```

---

*Dibuat khusus dengan cinta untuk Rini Rashifah 💕*
