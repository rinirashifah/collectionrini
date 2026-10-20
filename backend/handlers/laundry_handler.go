package handlers

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/rinirashifah/collectionrini-backend/database"
	"github.com/rinirashifah/collectionrini-backend/models"
	"gorm.io/gorm"
)

type StatusLaundryHandler struct{}

type StatusInput struct {
	Status        string  `json:"status" binding:"required"`
	NewLocationID *string `json:"new_location_id"`
	Notes         string  `json:"notes"`
}

func (h *StatusLaundryHandler) UpdateStatus(c *gin.Context) {
	id := c.Param("id")
	var input StatusInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "Status wajib diisi"})
		return
	}

	var item models.CollectionItem
	if err := database.DB.First(&item, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "error": "Barang tidak ditemukan"})
		return
	}

	err := database.DB.Transaction(func(tx *gorm.DB) error {
		oldLocationID := item.CurrentLocationID
		if input.NewLocationID != nil && *input.NewLocationID != "" &&
			(oldLocationID == nil || *oldLocationID != *input.NewLocationID) {
			item.CurrentLocationID = input.NewLocationID
			history := models.LocationHistory{
				ItemID:             item.ID,
				PreviousLocationID: oldLocationID,
				NewLocationID:      input.NewLocationID,
				MovedAt:            time.Now(),
				Notes:              input.Notes,
			}
			if err := tx.Create(&history).Error; err != nil {
				return err
			}
		}

		item.AvailabilityStatus = input.Status
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
		"message": "Status ketersediaan berhasil diperbarui",
		"data":    item,
	})
}

type StartLaundryInput struct {
	LaundryLocationID *string `json:"laundry_location_id"`
	Notes             string  `json:"notes"`
}

func (h *StatusLaundryHandler) StartLaundry(c *gin.Context) {
	id := c.Param("id")
	var input StartLaundryInput
	_ = c.ShouldBindJSON(&input)

	var item models.CollectionItem
	if err := database.DB.First(&item, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "error": "Barang tidak ditemukan"})
		return
	}

	err := database.DB.Transaction(func(tx *gorm.DB) error {
		// 1. Update location if provided
		if input.LaundryLocationID != nil && *input.LaundryLocationID != "" {
			oldLocID := item.CurrentLocationID
			item.CurrentLocationID = input.LaundryLocationID
			locHistory := models.LocationHistory{
				ItemID:             item.ID,
				PreviousLocationID: oldLocID,
				NewLocationID:      input.LaundryLocationID,
				MovedAt:            time.Now(),
				Notes:              "Masuk proses cuci (Laundry)",
			}
			if err := tx.Create(&locHistory).Error; err != nil {
				return err
			}
		}

		// 2. Set item status to In Laundry
		item.AvailabilityStatus = models.StatusInLaundry
		item.UpdatedAt = time.Now()
		if err := tx.Save(&item).Error; err != nil {
			return err
		}

		// 3. Create LaundryHistory cycle record
		laundryHistory := models.LaundryHistory{
			ItemID:    item.ID,
			StartedAt: time.Now(),
			Notes:     input.Notes,
		}
		return tx.Create(&laundryHistory).Error
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}

	database.DB.Preload("Category").Preload("CurrentLocation").First(&item, "id = ?", item.ID)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Barang telah masuk daftar pencucian (In Laundry)",
		"data":    item,
	})
}

type CompleteLaundryInput struct {
	DryingLocationID *string `json:"drying_location_id"`
	Notes            string  `json:"notes"`
}

func (h *StatusLaundryHandler) CompleteLaundry(c *gin.Context) {
	id := c.Param("id")
	var input CompleteLaundryInput
	_ = c.ShouldBindJSON(&input)

	var item models.CollectionItem
	if err := database.DB.First(&item, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "error": "Barang tidak ditemukan"})
		return
	}

	now := time.Now()
	err := database.DB.Transaction(func(tx *gorm.DB) error {
		// 1. Update location to drying/temporary location if provided
		if input.DryingLocationID != nil && *input.DryingLocationID != "" {
			oldLocID := item.CurrentLocationID
			item.CurrentLocationID = input.DryingLocationID
			locHistory := models.LocationHistory{
				ItemID:             item.ID,
				PreviousLocationID: oldLocID,
				NewLocationID:      input.DryingLocationID,
				MovedAt:            now,
				Notes:              "Selesai cuci, dipindahkan ke area jemuran/pengeringan",
			}
			if err := tx.Create(&locHistory).Error; err != nil {
				return err
			}
		}

		// 2. Set item status to Ready to Store
		item.AvailabilityStatus = models.StatusReadyToStore
		item.UpdatedAt = now
		if err := tx.Save(&item).Error; err != nil {
			return err
		}

		// 3. Complete open laundry history cycle
		var activeLaundry models.LaundryHistory
		if err := tx.Where("item_id = ? AND completed_at IS NULL", item.ID).
			Order("started_at DESC").
			First(&activeLaundry).Error; err == nil {
			activeLaundry.CompletedAt = &now
			if input.Notes != "" {
				if activeLaundry.Notes != "" {
					activeLaundry.Notes += " | " + input.Notes
				} else {
					activeLaundry.Notes = input.Notes
				}
			}
			return tx.Save(&activeLaundry).Error
		} else {
			// If not found, create completed entry
			activeLaundry = models.LaundryHistory{
				ItemID:      item.ID,
				StartedAt:   now,
				CompletedAt: &now,
				Notes:       "Pencucian diselesaikan",
			}
			return tx.Create(&activeLaundry).Error
		}
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}

	database.DB.Preload("Category").Preload("CurrentLocation").First(&item, "id = ?", item.ID)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Pencucian selesai! Barang kini 'Ready to Store' (Siap disimpan)",
		"data":    item,
	})
}

type StoreItemInput struct {
	TargetLocationID string  `json:"target_location_id" binding:"required"`
	PositionDetail   *string `json:"position_detail"`
	Notes            string  `json:"notes"`
}

func (h *StatusLaundryHandler) StoreItem(c *gin.Context) {
	id := c.Param("id")
	var input StoreItemInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "Target lokasi penyimpanan wajib dipilih"})
		return
	}

	var item models.CollectionItem
	if err := database.DB.First(&item, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "error": "Barang tidak ditemukan"})
		return
	}

	now := time.Now()
	err := database.DB.Transaction(func(tx *gorm.DB) error {
		oldLocID := item.CurrentLocationID
		item.CurrentLocationID = &input.TargetLocationID
		item.AvailabilityStatus = models.StatusAvailable
		if input.PositionDetail != nil {
			item.PositionDetail = *input.PositionDetail
		}
		item.UpdatedAt = now

		if err := tx.Save(&item).Error; err != nil {
			return err
		}

		note := input.Notes
		if note == "" {
			note = "Barang disimpan kembali ke lemari & siap digunakan (Available)"
		}

		locHistory := models.LocationHistory{
			ItemID:             item.ID,
			PreviousLocationID: oldLocID,
			NewLocationID:      &input.TargetLocationID,
			MovedAt:            now,
			Notes:              note,
		}
		return tx.Create(&locHistory).Error
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}

	database.DB.Preload("Category").Preload("CurrentLocation").First(&item, "id = ?", item.ID)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Barang berhasil disimpan dan kini Available ✨",
		"data":    item,
	})
}

type MoveLocationInput struct {
	NewLocationID  string  `json:"new_location_id" binding:"required"`
	PositionDetail *string `json:"position_detail"`
	Notes          string  `json:"notes"`
}

func (h *StatusLaundryHandler) MoveLocation(c *gin.Context) {
	id := c.Param("id")
	var input MoveLocationInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "Lokasi baru wajib dipilih"})
		return
	}

	var item models.CollectionItem
	if err := database.DB.First(&item, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "error": "Barang tidak ditemukan"})
		return
	}

	now := time.Now()
	err := database.DB.Transaction(func(tx *gorm.DB) error {
		oldLocID := item.CurrentLocationID
		item.CurrentLocationID = &input.NewLocationID
		if input.PositionDetail != nil {
			item.PositionDetail = *input.PositionDetail
		}
		item.UpdatedAt = now

		if err := tx.Save(&item).Error; err != nil {
			return err
		}

		note := input.Notes
		if note == "" {
			note = "Perpindahan lokasi penyimpanan"
		}

		locHistory := models.LocationHistory{
			ItemID:             item.ID,
			PreviousLocationID: oldLocID,
			NewLocationID:      &input.NewLocationID,
			MovedAt:            now,
			Notes:              note,
		}
		return tx.Create(&locHistory).Error
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}

	database.DB.Preload("Category").Preload("CurrentLocation").First(&item, "id = ?", item.ID)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Lokasi barang berhasil dipindahkan",
		"data":    item,
	})
}
