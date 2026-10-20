package database

import (
	"log"

	"github.com/glebarez/sqlite"
	"github.com/rinirashifah/collectionrini-backend/config"
	"github.com/rinirashifah/collectionrini-backend/models"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

var DB *gorm.DB

func InitDB(cfg *config.Config) *gorm.DB {
	var db *gorm.DB
	var err error

	gormConfig := &gorm.Config{
		Logger: logger.Default.LogMode(logger.Warn),
	}

	if cfg.DatabaseURL != "" {
		log.Printf("Connecting to PostgreSQL database...")
		db, err = gorm.Open(postgres.Open(cfg.DatabaseURL), gormConfig)
		if err != nil {
			log.Fatalf("Failed to connect to PostgreSQL: %v", err)
		}
		log.Println("PostgreSQL connected successfully.")
	} else {
		log.Println("DATABASE_URL is not set. Falling back to local SQLite database: collection_rini.db")
		db, err = gorm.Open(sqlite.Open("collection_rini.db"), gormConfig)
		if err != nil {
			log.Fatalf("Failed to connect to SQLite: %v", err)
		}
		log.Println("SQLite connected successfully.")
	}

	// Auto-migrate tables
	err = db.AutoMigrate(
		&models.Category{},
		&models.StorageLocation{},
		&models.CollectionItem{},
		&models.LocationHistory{},
		&models.LaundryHistory{},
	)
	if err != nil {
		log.Fatalf("Failed to auto-migrate database: %v", err)
	}
	log.Println("Database migration completed.")

	// Seed default categories and initial locations
	seedDefaults(db)

	DB = db
	return db
}

func seedDefaults(db *gorm.DB) {
	// Seed Categories if empty
	var catCount int64
	db.Model(&models.Category{}).Count(&catCount)
	if catCount == 0 {
		log.Println("Seeding default categories...")
		defaultCategories := []string{
			"Tops",
			"Bottoms",
			"Dresses & Outfits",
			"Hijab",
			"Shoes",
			"Sandals",
			"Bags",
			"Accessories",
			"Beauty & Personal Care",
			"Others",
		}
		for _, name := range defaultCategories {
			db.Create(&models.Category{Name: name})
		}
		log.Println("Default categories seeded.")
	}

	// Seed default Storage Locations if empty
	var locCount int64
	db.Model(&models.StorageLocation{}).Count(&locCount)
	if locCount == 0 {
		log.Println("Seeding default storage locations hierarchy...")
		// 1. Root: Rumah Rini
		rumah := models.StorageLocation{
			Name:         "Rumah",
			LocationType: "Rumah",
			Description:  "Rumah kediaman Rini",
		}
		db.Create(&rumah)

		// 2. Ruangan: Kamar Tidur
		kamar := models.StorageLocation{
			Name:             "Kamar Tidur",
			ParentLocationID: &rumah.ID,
			LocationType:     "Ruangan",
			Description:      "Kamar tidur utama Rini",
		}
		db.Create(&kamar)

		// 2b. Ruangan: Area Laundry & Jemuran
		laundryArea := models.StorageLocation{
			Name:             "Area Laundry",
			ParentLocationID: &rumah.ID,
			LocationType:     "Ruangan",
			Description:      "Area cuci dan setrika pakaian",
		}
		db.Create(&laundryArea)

		// 3. Furnitur dalam Kamar Tidur
		lemari := models.StorageLocation{
			Name:             "Lemari Pakaian",
			ParentLocationID: &kamar.ID,
			LocationType:     "Furnitur",
			Description:      "Lemari pakaian utama 3 pintu",
		}
		db.Create(&lemari)

		rakSepatu := models.StorageLocation{
			Name:             "Rak Sepatu",
			ParentLocationID: &kamar.ID,
			LocationType:     "Furnitur",
			Description:      "Rak sepatu kayu",
		}
		db.Create(&rakSepatu)

		mejaRias := models.StorageLocation{
			Name:             "Meja Rias",
			ParentLocationID: &kamar.ID,
			LocationType:     "Furnitur",
			Description:      "Meja rias dan penyimpanan aksesoris/skincare",
		}
		db.Create(&mejaRias)

		// 4. Sub-bagian Lemari Pakaian
		gantunganKiri := models.StorageLocation{
			Name:             "Gantungan Sisi Kiri",
			ParentLocationID: &lemari.ID,
			LocationType:     "Bagian Penyimpanan",
			Description:      "Gantungan untuk kemeja, blouse & dress",
		}
		db.Create(&gantunganKiri)

		gantunganKanan := models.StorageLocation{
			Name:             "Gantungan Sisi Kanan",
			ParentLocationID: &lemari.ID,
			LocationType:     "Bagian Penyimpanan",
			Description:      "Gantungan untuk jaket & outerwear",
		}
		db.Create(&gantunganKanan)

		laci1 := models.StorageLocation{
			Name:             "Laci 1 (Hijab & Inner)",
			ParentLocationID: &lemari.ID,
			LocationType:     "Bagian Penyimpanan",
			Description:      "Laci lipat koleksi hijab, pashmina & ciput",
		}
		db.Create(&laci1)

		laci2 := models.StorageLocation{
			Name:             "Laci 2 (Bawahan Lipat)",
			ParentLocationID: &lemari.ID,
			LocationType:     "Bagian Penyimpanan",
			Description:      "Celana santai, kulot, dan rok lipat",
		}
		db.Create(&laci2)

		// 4b. Sub-bagian Laundry
		keranjangLaundry := models.StorageLocation{
			Name:             "Keranjang Pakaian Kotor",
			ParentLocationID: &laundryArea.ID,
			LocationType:     "Posisi Spesifik",
			Description:      "Keranjang laundry pakaian kotor",
		}
		db.Create(&keranjangLaundry)

		jemuran := models.StorageLocation{
			Name:             "Jemuran & Pengeringan",
			ParentLocationID: &laundryArea.ID,
			LocationType:     "Posisi Spesifik",
			Description:      "Area pengeringan atau jemuran pakaian",
		}
		db.Create(&jemuran)

		mejaSetrika := models.StorageLocation{
			Name:             "Meja Setrika (Ready to Store)",
			ParentLocationID: &laundryArea.ID,
			LocationType:     "Posisi Spesifik",
			Description:      "Tempat barang bersih siap dilipat dan disimpan kembali",
		}
		db.Create(&mejaSetrika)

		log.Println("Default storage locations seeded.")
	}
}
