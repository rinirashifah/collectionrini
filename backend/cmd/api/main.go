package main

import (
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/rinirashifah/collectionrini-backend/config"
	"github.com/rinirashifah/collectionrini-backend/database"
	"github.com/rinirashifah/collectionrini-backend/handlers"
	"github.com/rinirashifah/collectionrini-backend/middleware"
	"github.com/rinirashifah/collectionrini-backend/models"
)

func main() {
	cfg := config.LoadConfig()
	gin.SetMode(cfg.GinMode)

	// Initialize Database
	db := database.InitDB(cfg)
	_ = db

	r := gin.Default()

	// CORS Setup
	r.Use(cors.New(cors.Config{
		AllowAllOrigins:  true,
		AllowMethods:     []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Accept", "Authorization", "X-API-Key"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	}))

	// Static folder for uploaded pictures
	_ = os.MkdirAll("./uploads", 0755)
	r.Static("/uploads", "./uploads")

	// Public Health Check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":    "healthy",
			"app":       "Koleksi Punya Rini Rashifah API",
			"timestamp": time.Now(),
		})
	})

	categoryHandler := &handlers.CategoryHandler{}
	locationHandler := &handlers.LocationHandler{}
	itemHandler := &handlers.ItemHandler{}
	statusLaundryHandler := &handlers.StatusLaundryHandler{}
	historyHandler := &handlers.HistoryHandler{}
	dashboardHandler := &handlers.DashboardHandler{}
	uploadHandler := handlers.NewUploadHandler(cfg)

	// API v1 group
	api := r.Group("/api/v1")
	{
		api.GET("/health", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{
				"status":    "healthy",
				"app":       "Koleksi Punya Rini Rashifah API",
				"timestamp": time.Now(),
			})
		})

		// Protected endpoints
		authorized := api.Group("")
		authorized.Use(middleware.APIKeyAuth(cfg.APIKey))
		{
			// Dashboard
			authorized.GET("/dashboard", dashboardHandler.GetDashboard)

			// Upload
			authorized.POST("/upload", uploadHandler.UploadImage)

			// Categories
			authorized.GET("/categories", categoryHandler.GetCategories)
			authorized.POST("/categories", categoryHandler.CreateCategory)
			authorized.PUT("/categories/:id", categoryHandler.UpdateCategory)
			authorized.DELETE("/categories/:id", categoryHandler.DeleteCategory)

			// Storage Locations
			authorized.GET("/locations", locationHandler.GetLocations)
			authorized.GET("/locations/tree", locationHandler.GetLocationTree)
			authorized.GET("/locations/:id", locationHandler.GetLocationByID)
			authorized.GET("/locations/:id/items", locationHandler.GetLocationItems)
			authorized.POST("/locations", locationHandler.CreateLocation)
			authorized.PUT("/locations/:id", locationHandler.UpdateLocation)
			authorized.DELETE("/locations/:id", locationHandler.DeleteLocation)

			// Items
			authorized.GET("/items", itemHandler.GetItems)
			authorized.GET("/items/:id", itemHandler.GetItemByID)
			authorized.POST("/items", itemHandler.CreateItem)
			authorized.PUT("/items/:id", itemHandler.UpdateItem)
			authorized.DELETE("/items/:id", itemHandler.DeleteItem)

			// Status, Laundry & Move actions
			authorized.PATCH("/items/:id/status", statusLaundryHandler.UpdateStatus)
			authorized.POST("/items/:id/laundry", statusLaundryHandler.StartLaundry)
			authorized.PATCH("/items/:id/laundry/complete", statusLaundryHandler.CompleteLaundry)
			authorized.POST("/items/:id/store", statusLaundryHandler.StoreItem)
			authorized.POST("/items/:id/move", statusLaundryHandler.MoveLocation)

			// Histories
			authorized.GET("/items/:id/location-history", historyHandler.GetItemLocationHistory)
			authorized.GET("/items/:id/laundry-history", historyHandler.GetItemLaundryHistory)

			// Sample Data Seeder
			authorized.POST("/seed-sample-data", func(c *gin.Context) {
				seedSampleData()
				c.JSON(http.StatusOK, gin.H{
					"success": true,
					"message": "Data contoh berhasil ditambahkan!",
				})
			})
		}
	}

	log.Printf("Server starting on port %s...", cfg.Port)
	if err := r.Run(":" + cfg.Port); err != nil {
		log.Fatalf("Failed to run server: %v", err)
	}
}

func seedSampleData() {
	var itemCount int64
	database.DB.Model(&models.CollectionItem{}).Count(&itemCount)
	if itemCount > 0 {
		return
	}

	// Find categories
	var tops, bottoms, hijab, dresses, bags, shoes models.Category
	database.DB.Where("name = ?", "Tops").First(&tops)
	database.DB.Where("name = ?", "Bottoms").First(&bottoms)
	database.DB.Where("name = ?", "Hijab").First(&hijab)
	database.DB.Where("name = ?", "Dresses & Outfits").First(&dresses)
	database.DB.Where("name = ?", "Bags").First(&bags)
	database.DB.Where("name = ?", "Shoes").First(&shoes)

	// Find locations
	var gantunganKiri, laci1, laci2, rakSepatu, keranjangLaundry, mejaSetrika models.StorageLocation
	database.DB.Where("name LIKE ?", "%Gantungan Sisi Kiri%").First(&gantunganKiri)
	database.DB.Where("name LIKE ?", "%Laci 1%").First(&laci1)
	database.DB.Where("name LIKE ?", "%Laci 2%").First(&laci2)
	database.DB.Where("name LIKE ?", "%Rak Sepatu%").First(&rakSepatu)
	database.DB.Where("name LIKE ?", "%Keranjang Pakaian Kotor%").First(&keranjangLaundry)
	database.DB.Where("name LIKE ?", "%Meja Setrika%").First(&mejaSetrika)

	now := time.Now()
	twoDaysAgo := now.Add(-48 * time.Hour)
	oneDayAgo := now.Add(-24 * time.Hour)
	threeHoursAgo := now.Add(-3 * time.Hour)

	// Item 1: Blouse Floral Pastel (Available)
	if tops.ID != "" && gantunganKiri.ID != "" {
		item1 := models.CollectionItem{
			Name:               "Blouse Floral Pastel",
			CategoryID:         tops.ID,
			ImageURL:           "https://images.unsplash.com/photo-1576995853123-5a10305d93c0?auto=format&fit=crop&w=600&q=80",
			Color:              "Soft Pink",
			Brand:              "Zara",
			Size:               "M",
			CurrentLocationID:  &gantunganKiri.ID,
			PositionDetail:     "Gantungan baris ke-3 dari depan",
			AvailabilityStatus: models.StatusAvailable,
			Notes:              "Bahan rayon adem, cocok untuk ngantor & hangout santai",
		}
		database.DB.Create(&item1)
		database.DB.Create(&models.LocationHistory{
			ItemID:        item1.ID,
			NewLocationID: &gantunganKiri.ID,
			MovedAt:       twoDaysAgo,
			Notes:         "Disimpan di lemari pakaian gantungan",
		})
	}

	// Item 2: Pashmina Ceruty Baby Pink (In Laundry)
	if hijab.ID != "" && keranjangLaundry.ID != "" {
		item2 := models.CollectionItem{
			Name:               "Pashmina Ceruty Baby Pink",
			CategoryID:         hijab.ID,
			ImageURL:           "https://images.unsplash.com/photo-1601924994987-69e26d50dc26?auto=format&fit=crop&w=600&q=80",
			Color:              "Baby Pink",
			Brand:              "Vanilla Hijab",
			Size:               "180 x 75 cm",
			CurrentLocationID:  &keranjangLaundry.ID,
			PositionDetail:     "Keranjang pakaian kotor",
			AvailabilityStatus: models.StatusInLaundry,
			Notes:              "Cuci manual dengan deterjen lembut",
		}
		database.DB.Create(&item2)
		database.DB.Create(&models.LaundryHistory{
			ItemID:    item2.ID,
			StartedAt: threeHoursAgo,
			Notes:     "Masuk cucian pagi hari",
		})
	}

	// Item 3: Kulot Linen Khaki (Ready to Store)
	if bottoms.ID != "" && mejaSetrika.ID != "" {
		item3 := models.CollectionItem{
			Name:               "Kulot Linen Khaki",
			CategoryID:         bottoms.ID,
			ImageURL:           "https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?auto=format&fit=crop&w=600&q=80",
			Color:              "Khaki / Cream",
			Brand:              "Uniqlo",
			Size:               "L",
			CurrentLocationID:  &mejaSetrika.ID,
			PositionDetail:     "Di atas meja setrika siap dilipat",
			AvailabilityStatus: models.StatusReadyToStore,
			Notes:              "Sudah kering dan disetrika rapi",
		}
		database.DB.Create(&item3)
		database.DB.Create(&models.LaundryHistory{
			ItemID:      item3.ID,
			StartedAt:   oneDayAgo,
			CompletedAt: &threeHoursAgo,
			Notes:       "Selesai dicuci dan dijemur",
		})
	}

	// Item 4: Gamis Brokat Dusty Rose (Available)
	if dresses.ID != "" && gantunganKiri.ID != "" {
		item4 := models.CollectionItem{
			Name:               "Gamis Brokat Dusty Rose",
			CategoryID:         dresses.ID,
			ImageURL:           "https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?auto=format&fit=crop&w=600&q=80",
			Color:              "Dusty Rose",
			Brand:              "RiaMiranda",
			Size:               "M",
			CurrentLocationID:  &gantunganKiri.ID,
			PositionDetail:     "Gantungan paling belakang dengan cover pelindung",
			AvailabilityStatus: models.StatusAvailable,
			Notes:              "Baju pesta / kondangan, jangan dilipat",
		}
		database.DB.Create(&item4)
	}

	// Item 5: Sneakers Putih Casual (In Use)
	if shoes.ID != "" && rakSepatu.ID != "" {
		item5 := models.CollectionItem{
			Name:               "Sneakers Putih Casual",
			CategoryID:         shoes.ID,
			ImageURL:           "https://images.unsplash.com/photo-1549298916-b41d501d3772?auto=format&fit=crop&w=600&q=80",
			Color:              "Putih",
			Brand:              "Nike Air Force",
			Size:               "38",
			CurrentLocationID:  &rakSepatu.ID,
			PositionDetail:     "Rak 2",
			AvailabilityStatus: models.StatusInUse,
			Notes:              "Sedang dipakai bepergian akhir pekan",
		}
		database.DB.Create(&item5)
	}
}
