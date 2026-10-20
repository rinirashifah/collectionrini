package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/rinirashifah/collectionrini-backend/database"
	"github.com/rinirashifah/collectionrini-backend/models"
)

type LocationHandler struct{}

type LocationNode struct {
	models.StorageLocation
	ItemCount int64           `json:"item_count"`
	Children  []*LocationNode `json:"children"`
}

func (h *LocationHandler) GetLocations(c *gin.Context) {
	var locations []models.StorageLocation
	if err := database.DB.Order("name ASC").Find(&locations).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}

	for i := range locations {
		var count int64
		database.DB.Model(&models.CollectionItem{}).Where("current_location_id = ?", locations[i].ID).Count(&count)
		locations[i].ItemCount = count
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    locations,
	})
}

func (h *LocationHandler) GetLocationTree(c *gin.Context) {
	var allLocations []models.StorageLocation
	if err := database.DB.Order("name ASC").Find(&allLocations).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}

	// Map of nodes
	nodeMap := make(map[string]*LocationNode)
	for _, loc := range allLocations {
		var count int64
		database.DB.Model(&models.CollectionItem{}).Where("current_location_id = ?", loc.ID).Count(&count)
		loc.ItemCount = count
		nodeMap[loc.ID] = &LocationNode{
			StorageLocation: loc,
			ItemCount:       count,
			Children:        []*LocationNode{},
		}
	}

	var rootNodes []*LocationNode
	for _, loc := range allLocations {
		node := nodeMap[loc.ID]
		if loc.ParentLocationID == nil || *loc.ParentLocationID == "" {
			rootNodes = append(rootNodes, node)
		} else {
			parentNode, exists := nodeMap[*loc.ParentLocationID]
			if exists {
				parentNode.Children = append(parentNode.Children, node)
			} else {
				rootNodes = append(rootNodes, node)
			}
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    rootNodes,
	})
}

func (h *LocationHandler) GetLocationByID(c *gin.Context) {
	id := c.Param("id")
	var location models.StorageLocation
	if err := database.DB.Preload("Parent").First(&location, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "error": "Lokasi tidak ditemukan"})
		return
	}

	var count int64
	database.DB.Model(&models.CollectionItem{}).Where("current_location_id = ?", id).Count(&count)
	location.ItemCount = count

	// Build breadcrumb
	var breadcrumbs []models.StorageLocation
	curr := &location
	for curr != nil {
		breadcrumbs = append([]models.StorageLocation{*curr}, breadcrumbs...)
		if curr.ParentLocationID != nil && *curr.ParentLocationID != "" {
			var parent models.StorageLocation
			if err := database.DB.First(&parent, "id = ?", *curr.ParentLocationID).Error; err == nil {
				curr = &parent
			} else {
				curr = nil
			}
		} else {
			curr = nil
		}
	}

	// Get child locations
	var children []models.StorageLocation
	database.DB.Where("parent_location_id = ?", id).Find(&children)
	for i := range children {
		var childCount int64
		database.DB.Model(&models.CollectionItem{}).Where("current_location_id = ?", children[i].ID).Count(&childCount)
		children[i].ItemCount = childCount
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"location":    location,
			"breadcrumbs": breadcrumbs,
			"children":    children,
		},
	})
}

func (h *LocationHandler) GetLocationItems(c *gin.Context) {
	id := c.Param("id")
	var items []models.CollectionItem
	if err := database.DB.
		Preload("Category").
		Preload("CurrentLocation").
		Where("current_location_id = ?", id).
		Order("name ASC").
		Find(&items).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    items,
	})
}

func (h *LocationHandler) CreateLocation(c *gin.Context) {
	var input struct {
		Name             string  `json:"name" binding:"required"`
		ParentLocationID *string `json:"parent_location_id"`
		LocationType     string  `json:"location_type"`
		Description      string  `json:"description"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "Nama lokasi wajib diisi"})
		return
	}

	location := models.StorageLocation{
		Name:             input.Name,
		ParentLocationID: input.ParentLocationID,
		LocationType:     input.LocationType,
		Description:      input.Description,
	}

	if err := database.DB.Create(&location).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"message": "Lokasi berhasil ditambahkan",
		"data":    location,
	})
}

func (h *LocationHandler) UpdateLocation(c *gin.Context) {
	id := c.Param("id")
	var location models.StorageLocation
	if err := database.DB.First(&location, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "error": "Lokasi tidak ditemukan"})
		return
	}

	var input struct {
		Name             string  `json:"name" binding:"required"`
		ParentLocationID *string `json:"parent_location_id"`
		LocationType     string  `json:"location_type"`
		Description      string  `json:"description"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "Nama lokasi wajib diisi"})
		return
	}

	// Prevent self parentage
	if input.ParentLocationID != nil && *input.ParentLocationID == id {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "Lokasi tidak boleh menjadi induk untuk dirinya sendiri"})
		return
	}

	location.Name = input.Name
	location.ParentLocationID = input.ParentLocationID
	location.LocationType = input.LocationType
	location.Description = input.Description

	if err := database.DB.Save(&location).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Lokasi berhasil diperbarui",
		"data":    location,
	})
}

func (h *LocationHandler) DeleteLocation(c *gin.Context) {
	id := c.Param("id")

	// Safe check 1: check if items stored in this location
	var itemCount int64
	database.DB.Model(&models.CollectionItem{}).Where("current_location_id = ?", id).Count(&itemCount)
	if itemCount > 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Lokasi tidak dapat dihapus karena masih ada barang yang tersimpan di sini. Pindahkan barang terlebih dahulu.",
		})
		return
	}

	// Safe check 2: check if child locations exist
	var childCount int64
	database.DB.Model(&models.StorageLocation{}).Where("parent_location_id = ?", id).Count(&childCount)
	if childCount > 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Lokasi tidak dapat dihapus karena memiliki sub-lokasi penyimpanan.",
		})
		return
	}

	if err := database.DB.Delete(&models.StorageLocation{}, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Lokasi berhasil dihapus",
	})
}
