package flash

import (
	"github.com/gorilla/sessions"
	"github.com/labstack/echo/v4"
)

const (
	flashSessionName = "willow_camp_flash"
)

// Message represents a flash message with type and content
type Message struct {
	Type    string // "success", "error", "warning", "info"
	Content string
}

// FlashStore manages flash messages using sessions
type FlashStore struct {
	store *sessions.CookieStore
}

// NewFlashStore creates a new flash message store
func NewFlashStore(secret string) *FlashStore {
	store := sessions.NewCookieStore([]byte(secret))
	store.Options = &sessions.Options{
		Path:     "/",
		MaxAge:   0, // Session cookie (deleted when browser closes)
		HttpOnly: true,
		Secure:   false, // Set to true in production with HTTPS
		SameSite: 2,     // Strict
	}
	return &FlashStore{store: store}
}

// SetSuccess sets a success flash message
func (f *FlashStore) SetSuccess(c echo.Context, message string) error {
	return f.set(c, "success", message)
}

// SetError sets an error flash message
func (f *FlashStore) SetError(c echo.Context, message string) error {
	return f.set(c, "error", message)
}

// SetWarning sets a warning flash message
func (f *FlashStore) SetWarning(c echo.Context, message string) error {
	return f.set(c, "warning", message)
}

// SetInfo sets an info flash message
func (f *FlashStore) SetInfo(c echo.Context, message string) error {
	return f.set(c, "info", message)
}

// set stores a flash message in the session
func (f *FlashStore) set(c echo.Context, msgType, content string) error {
	session, err := f.store.Get(c.Request(), flashSessionName)
	if err != nil {
		return err
	}

	// Store as separate keys to avoid gob encoding issues
	session.Values[msgType] = content

	return session.Save(c.Request(), c.Response())
}

// Get retrieves and clears flash messages
func (f *FlashStore) Get(c echo.Context) ([]Message, error) {
	session, err := f.store.Get(c.Request(), flashSessionName)
	if err != nil {
		return nil, err
	}

	var messages []Message

	// Check each message type
	for _, msgType := range []string{"success", "error", "warning", "info"} {
		if val, ok := session.Values[msgType]; ok {
			if content, ok := val.(string); ok {
				messages = append(messages, Message{Type: msgType, Content: content})
			}
			delete(session.Values, msgType)
		}
	}

	// Save to clear the messages
	if len(messages) > 0 {
		session.Save(c.Request(), c.Response())
	}

	return messages, nil
}
