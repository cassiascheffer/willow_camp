package models

import (
	"time"

	"github.com/google/uuid"
)

// User represents a user account
type User struct {
	ID                 uuid.UUID  `db:"id" json:"id"`
	Email              string     `db:"email" json:"email"`
	EncryptedPassword  string     `db:"encrypted_password" json:"-"`
	Name               *string    `db:"name" json:"name"`
	ResetPasswordToken *string    `db:"reset_password_token" json:"-"`
	ResetPasswordSentAt *time.Time `db:"reset_password_sent_at" json:"-"`
	RememberCreatedAt  *time.Time `db:"remember_created_at" json:"-"`
	SignInCount        int        `db:"sign_in_count" json:"sign_in_count"`
	CurrentSignInAt    *time.Time `db:"current_sign_in_at" json:"-"`
	LastSignInAt       *time.Time `db:"last_sign_in_at" json:"-"`
	CurrentSignInIP    *string    `db:"current_sign_in_ip" json:"-"`
	LastSignInIP       *string    `db:"last_sign_in_ip" json:"-"`
	ConfirmationToken  *string    `db:"confirmation_token" json:"-"`
	ConfirmedAt        *time.Time `db:"confirmed_at" json:"-"`
	ConfirmationSentAt *time.Time `db:"confirmation_sent_at" json:"-"`
	UnconfirmedEmail   *string    `db:"unconfirmed_email" json:"-"`
	BlogsCount         int        `db:"blogs_count" json:"blogs_count"`
	CreatedAt          time.Time  `db:"created_at" json:"created_at"`
	UpdatedAt          time.Time  `db:"updated_at" json:"updated_at"`

	// Not from database - populated by separate queries
	Blogs []*Blog `json:"blogs,omitempty"`
}

// Blog represents a multi-tenant blog
type Blog struct {
	ID                  uuid.UUID  `db:"id" json:"id"`
	UserID              uuid.UUID  `db:"user_id" json:"user_id"`
	Subdomain           *string    `db:"subdomain" json:"subdomain"`
	Title               *string    `db:"title" json:"title"`
	Slug                *string    `db:"slug" json:"slug"`
	MetaDescription     *string    `db:"meta_description" json:"meta_description"`
	FaviconEmoji        *string    `db:"favicon_emoji" json:"favicon_emoji"`
	CustomDomain        *string    `db:"custom_domain" json:"custom_domain"`
	Theme               string     `db:"theme" json:"theme"`
	PostFooterMarkdown  *string    `db:"post_footer_markdown" json:"post_footer_markdown"`
	NoIndex             bool       `db:"no_index" json:"no_index"`
	Primary             bool       `db:"primary" json:"primary"`
	CreatedAt           time.Time  `db:"created_at" json:"created_at"`
	UpdatedAt           time.Time  `db:"updated_at" json:"updated_at"`
}

// Post represents a blog post or page (Single Table Inheritance)
type Post struct {
	ID                 uuid.UUID  `db:"id" json:"id"`
	BlogID             uuid.UUID  `db:"blog_id" json:"blog_id"`
	AuthorID           uuid.UUID  `db:"author_id" json:"author_id"`
	Title              *string    `db:"title" json:"title"`
	Slug               *string    `db:"slug" json:"slug"`
	BodyMarkdown       *string    `db:"body_markdown" json:"body_markdown"`
	MetaDescription    *string    `db:"meta_description" json:"meta_description"`
	Published          *bool      `db:"published" json:"published"`
	PublishedAt        *time.Time `db:"published_at" json:"published_at"`
	Type               *string    `db:"type" json:"type"`
	HasMermaidDiagrams bool       `db:"has_mermaid_diagrams" json:"has_mermaid_diagrams"`
	Featured           bool       `db:"featured" json:"featured"`
	CreatedAt          time.Time  `db:"created_at" json:"created_at"`
	UpdatedAt          time.Time  `db:"updated_at" json:"updated_at"`

	// Not from database - populated by joins or separate queries
	Author *User  `json:"author,omitempty"`
	Blog   *Blog  `json:"blog,omitempty"`
	Tags   []Tag  `json:"tags,omitempty"`
}

// IsPage returns true if this is a Page (vs a Post)
func (p *Post) IsPage() bool {
	return p.Type != nil && *p.Type == "Page"
}

// IsPublished returns true if the post is published
func (p *Post) IsPublished() bool {
	return p.Published != nil && *p.Published
}

// Tag represents a tag for categorizing posts
type Tag struct {
	ID            uuid.UUID `db:"id" json:"id"`
	Name          string    `db:"name" json:"name"`
	Slug          *string   `db:"slug" json:"slug"`
	TaggingsCount int       `db:"taggings_count" json:"taggings_count"`
	CreatedAt     time.Time `db:"created_at" json:"created_at"`
	UpdatedAt     time.Time `db:"updated_at" json:"updated_at"`
}

// Tagging represents the many-to-many relationship between posts and tags
type Tagging struct {
	ID           uuid.UUID  `db:"id" json:"id"`
	TagID        uuid.UUID  `db:"tag_id" json:"tag_id"`
	TaggableID   uuid.UUID  `db:"taggable_id" json:"taggable_id"`
	TaggableType string     `db:"taggable_type" json:"taggable_type"`
	TaggerID     *uuid.UUID `db:"tagger_id" json:"tagger_id"`
	TaggerType   *string    `db:"tagger_type" json:"tagger_type"`
	Context      *string    `db:"context" json:"context"`
	Tenant       *string    `db:"tenant" json:"tenant"`
	CreatedAt    time.Time  `db:"created_at" json:"created_at"`
}

// UserToken represents an API token for authentication
type UserToken struct {
	ID        uuid.UUID  `db:"id" json:"id"`
	UserID    uuid.UUID  `db:"user_id" json:"user_id"`
	Token     string     `db:"token" json:"token"`
	Name      string     `db:"name" json:"name"`
	ExpiresAt *time.Time `db:"expires_at" json:"expires_at"`
	CreatedAt time.Time  `db:"created_at" json:"created_at"`
	UpdatedAt time.Time  `db:"updated_at" json:"updated_at"`
}
