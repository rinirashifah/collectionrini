package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
)

func APIKeyAuth(expectedKey string) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Public health check
		if c.Request.URL.Path == "/health" || c.Request.URL.Path == "/api/v1/health" {
			c.Next()
			return
		}

		// If no key configured, proceed
		if expectedKey == "" {
			c.Next()
			return
		}

		// 1. Check X-API-Key header
		clientKey := c.GetHeader("X-API-Key")

		// 2. Check Authorization Bearer header
		if clientKey == "" {
			authHeader := c.GetHeader("Authorization")
			if strings.HasPrefix(authHeader, "Bearer ") {
				clientKey = strings.TrimPrefix(authHeader, "Bearer ")
			}
		}

		// 3. Check query param
		if clientKey == "" {
			clientKey = c.Query("api_key")
		}

		if clientKey != expectedKey {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"success": false,
				"error":   "Unauthorized: Invalid or missing API key. Please check your credentials.",
			})
			return
		}

		c.Next()
	}
}
