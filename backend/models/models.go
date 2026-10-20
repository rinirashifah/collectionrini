package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

const (
	StatusAvailable    = "Available"
	StatusInUse        = "In Use"
	StatusInLaundry    = "In Laundry"
	StatusReadyToStore = "Ready to Store"
	StatusUnavailable  = "Unavailable"
)

type Category struct {
	ID        string    `gorm:"type:varchar(36);primaryKey" json:"id"`
	Name      string    `gorm:"type:varchar(100);not null;unique" json:"name" binding:"required"`
	CreatedAt time.Time `json:"created_at"`
}

func (c *Category) BeforeCreate(tx *gorm.DB) error {
	if c.ID == "" {
		c.ID = uuid.New().String()
	}
	return nil
}

type StorageLocation struct {
	ID               string             `gorm:"type:varchar(36);primaryKey" json:"id"`
	Name             string             `gorm:"type:varchar(150);not null" json:"name" binding:"required"`
	ParentLocationID *string            `gorm:"type:varchar(36);index" json:"parent_location_id"`
	LocationType     string             `gorm:"type:varchar(50)" json:"location_type"` // e.g. Rumah, Ruangan, Furnitur, Bagian, Posisi Spesifik
	Description      string             `gorm:"type:text" json:"description"`
	CreatedAt        time.Time          `json:"created_at"`
	UpdatedAt        time.Time          `json:"updated_at"`
	Parent           *StorageLocation   `gorm:"foreignKey:ParentLocationID;references:ID" json:"parent,omitempty"`
	Children         []*StorageLocation `gorm:"foreignKey:ParentLocationID;references:ID" json:"children,omitempty"`
	ItemCount        int64              `gorm:"-" json:"item_count"`
}

func (l *StorageLocation) BeforeCreate(tx *gorm.DB) error {
	if l.ID == "" {
		l.ID = uuid.New().String()
	}
	return nil
}

type CollectionItem struct {
	ID                 string           `gorm:"type:varchar(36);primaryKey" json:"id"`
	Name               string           `gorm:"type:varchar(200);not null" json:"name" binding:"required"`
	CategoryID         string           `gorm:"type:varchar(36);not null;index" json:"category_id" binding:"required"`
	ImageURL           string           `gorm:"type:text" json:"image_url"`
	Color              string           `gorm:"type:varchar(50)" json:"color"`
	Brand              string           `gorm:"type:varchar(100)" json:"brand"`
	Size               string           `gorm:"type:varchar(50)" json:"size"`
	CurrentLocationID  *string          `gorm:"type:varchar(36);index" json:"current_location_id"`
	PositionDetail     string           `gorm:"type:text" json:"position_detail"`
	AvailabilityStatus string           `gorm:"type:varchar(30);not null;default:'Available';index" json:"availability_status"`
	Notes              string           `gorm:"type:text" json:"notes"`
	CreatedAt          time.Time        `json:"created_at"`
	UpdatedAt          time.Time        `json:"updated_at"`
	Category           *Category        `gorm:"foreignKey:CategoryID;references:ID" json:"category,omitempty"`
	CurrentLocation    *StorageLocation `gorm:"foreignKey:CurrentLocationID;references:ID" json:"current_location,omitempty"`
}

func (i *CollectionItem) BeforeCreate(tx *gorm.DB) error {
	if i.ID == "" {
		i.ID = uuid.New().String()
	}
	if i.AvailabilityStatus == "" {
		i.AvailabilityStatus = StatusAvailable
	}
	return nil
}

type LocationHistory struct {
	ID                 string           `gorm:"type:varchar(36);primaryKey" json:"id"`
	ItemID             string           `gorm:"type:varchar(36);not null;index" json:"item_id"`
	PreviousLocationID *string          `gorm:"type:varchar(36)" json:"previous_location_id"`
	NewLocationID      *string          `gorm:"type:varchar(36)" json:"new_location_id"`
	MovedAt            time.Time        `json:"moved_at"`
	Notes              string           `gorm:"type:text" json:"notes"`
	PreviousLocation   *StorageLocation `gorm:"foreignKey:PreviousLocationID;references:ID" json:"previous_location,omitempty"`
	NewLocation        *StorageLocation `gorm:"foreignKey:NewLocationID;references:ID" json:"new_location,omitempty"`
}

func (h *LocationHistory) BeforeCreate(tx *gorm.DB) error {
	if h.ID == "" {
		h.ID = uuid.New().String()
	}
	if h.MovedAt.IsZero() {
		h.MovedAt = time.Now()
	}
	return nil
}

type LaundryHistory struct {
	ID          string     `gorm:"type:varchar(36);primaryKey" json:"id"`
	ItemID      string     `gorm:"type:varchar(36);not null;index" json:"item_id"`
	StartedAt   time.Time  `json:"started_at"`
	CompletedAt *time.Time `json:"completed_at"`
	Notes       string     `gorm:"type:text" json:"notes"`
	CreatedAt   time.Time  `json:"created_at"`
}

func (l *LaundryHistory) BeforeCreate(tx *gorm.DB) error {
	if l.ID == "" {
		l.ID = uuid.New().String()
	}
	if l.StartedAt.IsZero() {
		l.StartedAt = time.Now()
	}
	return nil
}
