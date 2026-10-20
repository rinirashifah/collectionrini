package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/rinirashifah/collectionrini-backend/database"
	"github.com/rinirashifah/collectionrini-backend/models"
)

type HistoryHandler struct{}

func (h *HistoryHandler) GetItemLocationHistory(c *gin.Context) {
	id := c.Param("id")

	var histories []models.LocationHistory
	if err := database.DB.
		Preload("PreviousLocation").
		Preload("NewLocation").
		Where("item_id = ?", id).
		Order("moved_at DESC").
		Find(&histories).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    histories,
	})
}

func (h *HistoryHandler) GetItemLaundryHistory(c *gin.Context) {
	id := c.Param("id")

	var histories []models.LaundryHistory
	if err := database.DB.
		Where("item_id = ?", id).
		Order("started_at DESC").
		Find(&histories).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    histories,
	})
}
