package handlers

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/cloudinary/cloudinary-go/v2"
	"github.com/cloudinary/cloudinary-go/v2/api/uploader"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/rinirashifah/collectionrini-backend/config"
)

type UploadHandler struct {
	cfg *config.Config
}

func NewUploadHandler(cfg *config.Config) *UploadHandler {
	return &UploadHandler{cfg: cfg}
}

func (h *UploadHandler) UploadImage(c *gin.Context) {
	file, header, err := c.Request.FormFile("image")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "Berkas gambar tidak ditemukan pada form-data (key: image)"})
		return
	}
	defer file.Close()

	ext := strings.ToLower(filepath.Ext(header.Filename))
	if ext != ".jpg" && ext != ".jpeg" && ext != ".png" && ext != ".webp" && ext != ".gif" && ext != ".heic" {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "Format berkas tidak didukung. Gunakan JPG, PNG, atau WEBP."})
		return
	}

	// 1. Check if Cloudinary is configured
	if h.cfg.CloudinaryCloudName != "" && h.cfg.CloudinaryAPIKey != "" && h.cfg.CloudinaryAPISecret != "" {
		cld, err := cloudinary.NewFromParams(h.cfg.CloudinaryCloudName, h.cfg.CloudinaryAPIKey, h.cfg.CloudinaryAPISecret)
		if err == nil {
			uploadParams := uploader.UploadParams{
				Folder:       h.cfg.CloudinaryFolder,
				ResourceType: "image",
			}
			res, err := cld.Upload.Upload(context.Background(), file, uploadParams)
			if err == nil && res.SecureURL != "" {
				c.JSON(http.StatusOK, gin.H{
					"success": true,
					"message": "Gambar berhasil diunggah ke Cloudinary",
					"url":     res.SecureURL,
				})
				return
			}
		}
	}

	// 2. Local Fallback when Cloudinary is not configured or in local development
	uploadsDir := "./uploads"
	if err := os.MkdirAll(uploadsDir, 0755); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": "Gagal membuat direktori unggahan lokal"})
		return
	}

	uniqueFilename := fmt.Sprintf("%d_%s%s", time.Now().UnixNano(), uuid.New().String()[:8], ext)
	targetPath := filepath.Join(uploadsDir, uniqueFilename)

	dst, err := os.Create(targetPath)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": "Gagal menyimpan berkas lokal"})
		return
	}
	defer dst.Close()

	if _, err := io.Copy(dst, file); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": "Gagal menyalin isi berkas"})
		return
	}

	// Determine host URL
	scheme := "http"
	if c.Request.TLS != nil || c.GetHeader("X-Forwarded-Proto") == "https" {
		scheme = "https"
	}
	host := c.Request.Host
	imageURL := fmt.Sprintf("%s://%s/uploads/%s", scheme, host, uniqueFilename)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Gambar berhasil disimpan",
		"url":     imageURL,
	})
}
