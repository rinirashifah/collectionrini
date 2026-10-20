package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/rinirashifah/collectionrini-backend/database"
	"github.com/rinirashifah/collectionrini-backend/models"
)

type DashboardHandler struct{}

type StatusCountSummary struct {
	Total        int64 `json:"total"`
	Available    int64 `json:"available"`
	InUse        int64 `json:"in_use"`
	InLaundry    int64 `json:"in_laundry"`
	ReadyToStore int64 `json:"ready_to_store"`
	Unavailable  int64 `json:"unavailable"`
}

type DashboardData struct {
	Summary           StatusCountSummary      `json:"summary"`
	InLaundryItems    []models.CollectionItem `json:"in_laundry_items"`
	ReadyToStoreItems []models.CollectionItem `json:"ready_to_store_items"`
	RecentItems       []models.CollectionItem `json:"recent_items"`
	TotalCategories   int64                   `json:"total_categories"`
	TotalLocations    int64                   `json:"total_locations"`
}

func (h *DashboardHandler) GetDashboard(c *gin.Context) {
	var summary StatusCountSummary

	database.DB.Model(&models.CollectionItem{}).Count(&summary.Total)
	database.DB.Model(&models.CollectionItem{}).Where("availability_status = ?", models.StatusAvailable).Count(&summary.Available)
	database.DB.Model(&models.CollectionItem{}).Where("availability_status = ?", models.StatusInUse).Count(&summary.InUse)
	database.DB.Model(&models.CollectionItem{}).Where("availability_status = ?", models.StatusInLaundry).Count(&summary.InLaundry)
	database.DB.Model(&models.CollectionItem{}).Where("availability_status = ?", models.StatusReadyToStore).Count(&summary.ReadyToStore)
	database.DB.Model(&models.CollectionItem{}).Where("availability_status = ?", models.StatusUnavailable).Count(&summary.Unavailable)

	var inLaundryItems []models.CollectionItem
	database.DB.
		Preload("Category").
		Preload("CurrentLocation").
		Where("availability_status = ?", models.StatusInLaundry).
		Order("updated_at DESC").
		Limit(10).
		Find(&inLaundryItems)

	var readyToStoreItems []models.CollectionItem
	database.DB.
		Preload("Category").
		Preload("CurrentLocation").
		Where("availability_status = ?", models.StatusReadyToStore).
		Order("updated_at DESC").
		Limit(10).
		Find(&readyToStoreItems)

	var recentItems []models.CollectionItem
	database.DB.
		Preload("Category").
		Preload("CurrentLocation").
		Order("updated_at DESC").
		Limit(8).
		Find(&recentItems)

	var totalCategories int64
	database.DB.Model(&models.Category{}).Count(&totalCategories)

	var totalLocations int64
	database.DB.Model(&models.StorageLocation{}).Count(&totalLocations)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": DashboardData{
			Summary:           summary,
			InLaundryItems:    inLaundryItems,
			ReadyToStoreItems: readyToStoreItems,
			RecentItems:       recentItems,
			TotalCategories:   totalCategories,
			TotalLocations:    totalLocations,
		},
	})
}
