package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/rinirashifah/collectionrini-backend/database"
	"github.com/rinirashifah/collectionrini-backend/models"
)

type CategoryHandler struct{}

func (h *CategoryHandler) GetCategories(c *gin.Context) {
	var categories []models.Category
	if err := database.DB.Order("name ASC").Find(&categories).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}

	// Calculate item counts per category
	type CategoryResponse struct {
		models.Category
		ItemCount int64 `json:"item_count"`
	}

	var response []CategoryResponse
	for _, cat := range categories {
		var count int64
		database.DB.Model(&models.CollectionItem{}).Where("category_id = ?", cat.ID).Count(&count)
		response = append(response, CategoryResponse{
			Category:  cat,
			ItemCount: count,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    response,
	})
}

func (h *CategoryHandler) CreateCategory(c *gin.Context) {
	var input struct {
		Name string `json:"name" binding:"required"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "Category name is required"})
		return
	}

	// Check if already exists
	var existing models.Category
	if err := database.DB.Where("LOWER(name) = LOWER(?)", input.Name).First(&existing).Error; err == nil {
		c.JSON(http.StatusConflict, gin.H{"success": false, "error": "Kategori dengan nama ini sudah ada"})
		return
	}

	category := models.Category{
		Name: input.Name,
	}

	if err := database.DB.Create(&category).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"message": "Kategori berhasil ditambahkan",
		"data":    category,
	})
}

func (h *CategoryHandler) UpdateCategory(c *gin.Context) {
	id := c.Param("id")
	var category models.Category
	if err := database.DB.First(&category, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "error": "Kategori tidak ditemukan"})
		return
	}

	var input struct {
		Name string `json:"name" binding:"required"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "Category name is required"})
		return
	}

	category.Name = input.Name
	if err := database.DB.Save(&category).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Kategori berhasil diperbarui",
		"data":    category,
	})
}

func (h *CategoryHandler) DeleteCategory(c *gin.Context) {
	id := c.Param("id")

	// Check if any items belong to this category
	var count int64
	database.DB.Model(&models.CollectionItem{}).Where("category_id = ?", id).Count(&count)
	if count > 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Kategori tidak dapat dihapus karena masih digunakan oleh koleksi barang.",
		})
		return
	}

	if err := database.DB.Delete(&models.Category{}, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Kategori berhasil dihapus",
	})
}
