package config

import (
	"os"

	"github.com/joho/godotenv"
)

type Config struct {
	Port                string
	DatabaseURL         string
	GinMode             string
	APIKey              string
	CloudinaryCloudName string
	CloudinaryAPIKey    string
	CloudinaryAPISecret string
	CloudinaryFolder    string
}

func LoadConfig() *Config {
	// Load .env if present (ignore error if running on Render/production)
	_ = godotenv.Load()

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	ginMode := os.Getenv("GIN_MODE")
	if ginMode == "" {
		ginMode = "debug"
	}

	apiKey := os.Getenv("API_KEY")
	if apiKey == "" {
		// Default secret key for Rini's app
		apiKey = "rini-secret-2024"
	}

	cloudinaryFolder := os.Getenv("CLOUDINARY_FOLDER")
	if cloudinaryFolder == "" {
		cloudinaryFolder = "koleksi_rini"
	}

	return &Config{
		Port:                port,
		DatabaseURL:         os.Getenv("DATABASE_URL"),
		GinMode:             ginMode,
		APIKey:              apiKey,
		CloudinaryCloudName: os.Getenv("CLOUDINARY_CLOUD_NAME"),
		CloudinaryAPIKey:    os.Getenv("CLOUDINARY_API_KEY"),
		CloudinaryAPISecret: os.Getenv("CLOUDINARY_API_SECRET"),
		CloudinaryFolder:    cloudinaryFolder,
	}
}
