package handlers

import (
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/rinirashifah/collectionrini-backend/database"
	"github.com/rinirashifah/collectionrini-backend/models"
	"gorm.io/gorm"
)

type ItemHandler struct{}

func (h *ItemHandler) GetItems(c *gin.Context) {
	query := database.DB.Model(&models.CollectionItem{}).
		Preload("Category").
		Preload("CurrentLocation")

	// Search filter
	search := c.Query("search")
	if search != "" {
		searchPattern := "%" + strings.ToLower(search) + "%"
		query = query.Where("LOWER(name) LIKE ? OR LOWER(brand) LIKE ? OR LOWER(color) LIKE ? OR LOWER(notes) LIKE ?",
			searchPattern, searchPattern, searchPattern, searchPattern)
	}

	// Category filter
	categoryID := c.Query("category_id")
	if categoryID != "" {
		query = query.Where("category_id = ?", categoryID)
	}

	// Availability Status filter
	status := c.Query("status")
	if status != "" {
		query = query.Where("availability_status = ?", status)
	}

	// Location filter
	locationID := c.Query("location_id")
	if locationID != "" {
		query = query.Where("current_location_id = ?", locationID)
	}

	// Color filter
	color := c.Query("color")
	if color != "" {
		query = query.Where("LOWER(color) = ?", strings.ToLower(color))
	}

	// Brand filter
	brand := c.Query("brand")
	if brand != "" {
		query = query.Where("LOWER(brand) = ?", strings.ToLower(brand))
	}

	var items []models.CollectionItem
	if err := query.Order("updated_at DESC").Find(&items).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"count":   len(items),
		"data":    items,
	})
}

func (h *ItemHandler) GetItemByID(c *gin.Context) {
	id := c.Param("id")
	var item models.CollectionItem
	if err := database.DB.
		Preload("Category").
		Preload("CurrentLocation").
		First(&item, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "error": "Barang tidak ditemukan"})
		return
	}

	// Fetch location histories
	var locationHistories []models.LocationHistory
	database.DB.
		Preload("PreviousLocation").
		Preload("NewLocation").
		Where("item_id = ?", id).
		Order("moved_at DESC").
		Limit(20).
		Find(&locationHistories)

	// Fetch laundry histories
	var laundryHistories []models.LaundryHistory
	database.DB.
		Where("item_id = ?", id).
		Order("started_at DESC").
		Limit(20).
		Find(&laundryHistories)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"item":               item,
			"location_histories": locationHistories,
			"laundry_histories":  laundryHistories,
		},
	})
}

type ItemInput struct {
	Name               string  `json:"name" binding:"required"`
	CategoryID         string  `json:"category_id" binding:"required"`
	ImageURL           string  `json:"image_url"`
	Color              string  `json:"color"`
	Brand              string  `json:"brand"`
	Size               string  `json:"size"`
	CurrentLocationID  *string `json:"current_location_id"`
	PositionDetail     string  `json:"position_detail"`
	AvailabilityStatus string  `json:"availability_status"`
	Notes              string  `json:"notes"`
}

func (h *ItemHandler) CreateItem(c *gin.Context) {
	var input ItemInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "Nama dan Kategori wajib diisi"})
		return
	}

	// Check category exists
	var category models.Category
	if err := database.DB.First(&category, "id = ?", input.CategoryID).Error; err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "Kategori tidak valid"})
		return
	}

	// Default status
	status := input.AvailabilityStatus
	if status == "" {
		status = models.StatusAvailable
	}

	var item models.CollectionItem
	err := database.DB.Transaction(func(tx *gorm.DB) error {
		item = models.CollectionItem{
			Name:               input.Name,
			CategoryID:         input.CategoryID,
			ImageURL:           input.ImageURL,
			Color:              input.Color,
			Brand:              input.Brand,
			Size:               input.Size,
			CurrentLocationID:  input.CurrentLocationID,
			PositionDetail:     input.PositionDetail,
			AvailabilityStatus: status,
			Notes:              input.Notes,
		}

		if err := tx.Create(&item).Error; err != nil {
			return err
		}

		// If initial location provided, record to LocationHistory
		if input.CurrentLocationID != nil && *input.CurrentLocationID != "" {
			history := models.LocationHistory{
				ItemID:             item.ID,
				PreviousLocationID: nil,
				NewLocationID:      input.CurrentLocationID,
				MovedAt:            time.Now(),
				Notes:              "Barang pertama kali ditambahkan ke penyimpanan",
			}
			if err := tx.Create(&history).Error; err != nil {
				return err
			}
		}

		return nil
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}

	// Preload relationships for response
	database.DB.Preload("Category").Preload("CurrentLocation").First(&item, "id = ?", item.ID)

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"message": "Barang berhasil disimpan",
		"data":    item,
	})
}

func (h *ItemHandler) UpdateItem(c *gin.Context) {
	id := c.Param("id")
	var item models.CollectionItem
	if err := database.DB.First(&item, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "error": "Barang tidak ditemukan"})
		return
	}

	var input ItemInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "Input tidak valid"})
		return
	}

	err := database.DB.Transaction(func(tx *gorm.DB) error {
		// Detect location change
		oldLocID := item.CurrentLocationID
		newLocID := input.CurrentLocationID

		locChanged := false
		if (oldLocID == nil && newLocID != nil && *newLocID != "") ||
			(oldLocID != nil && newLocID == nil) ||
			(oldLocID != nil && newLocID != nil && *oldLocID != *newLocID) {
			locChanged = true
		}

		if locChanged {
			history := models.LocationHistory{
				ItemID:             item.ID,
				PreviousLocationID: oldLocID,
				NewLocationID:      newLocID,
				MovedAt:            time.Now(),
				Notes:              "Lokasi diperbarui melalui edit barang",
			}
			if err := tx.Create(&history).Error; err != nil {
				return err
			}
		}

		item.Name = input.Name
		item.CategoryID = input.CategoryID
		item.ImageURL = input.ImageURL
		item.Color = input.Color
		item.Brand = input.Brand
		item.Size = input.Size
		item.CurrentLocationID = input.CurrentLocationID
		item.PositionDetail = input.PositionDetail
		if input.AvailabilityStatus != "" {
			item.AvailabilityStatus = input.AvailabilityStatus
		}
		item.Notes = input.Notes
		item.UpdatedAt = time.Now()

		return tx.Save(&item).Error
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}

	database.DB.Preload("Category").Preload("CurrentLocation").First(&item, "id = ?", item.ID)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Barang berhasil diperbarui",
		"data":    item,
	})
}

func (h *ItemHandler) DeleteItem(c *gin.Context) {
	id := c.Param("id")

	err := database.DB.Transaction(func(tx *gorm.DB) error {
		// Delete related histories
		if err := tx.Where("item_id = ?", id).Delete(&models.LocationHistory{}).Error; err != nil {
			return err
		}
		if err := tx.Where("item_id = ?", id).Delete(&models.LaundryHistory{}).Error; err != nil {
			return err
		}
		// Delete item
		return tx.Delete(&models.CollectionItem{}, "id = ?", id).Error
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Barang berhasil dihapus",
	})
}
