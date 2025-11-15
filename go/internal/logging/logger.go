package logging

import (
	"fmt"
	"log"
	"os"
	"time"

	"github.com/labstack/echo/v4"
)

// Logger wraps standard logger with structured logging
type Logger struct {
	*log.Logger
}

// NewLogger creates a new structured logger
func NewLogger() *Logger {
	return &Logger{
		Logger: log.New(os.Stdout, "", 0),
	}
}

// Info logs an info message
func (l *Logger) Info(msg string, fields ...interface{}) {
	l.log("INFO", msg, fields...)
}

// Error logs an error message
func (l *Logger) Error(msg string, fields ...interface{}) {
	l.log("ERROR", msg, fields...)
}

// Warn logs a warning message
func (l *Logger) Warn(msg string, fields ...interface{}) {
	l.log("WARN", msg, fields...)
}

// Debug logs a debug message
func (l *Logger) Debug(msg string, fields ...interface{}) {
	l.log("DEBUG", msg, fields...)
}

func (l *Logger) log(level, msg string, fields ...interface{}) {
	timestamp := time.Now().Format(time.RFC3339)
	output := fmt.Sprintf("[%s] %s: %s", timestamp, level, msg)

	if len(fields) > 0 {
		output += " |"
		for i := 0; i < len(fields); i += 2 {
			if i+1 < len(fields) {
				output += fmt.Sprintf(" %v=%v", fields[i], fields[i+1])
			}
		}
	}

	l.Println(output)
}

// RequestLogger returns an Echo middleware for request logging
func RequestLogger(logger *Logger) echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			start := time.Now()

			err := next(c)

			req := c.Request()
			res := c.Response()

			latency := time.Since(start)

			logger.Info("request",
				"method", req.Method,
				"path", req.URL.Path,
				"status", res.Status,
				"latency", latency.String(),
				"ip", c.RealIP(),
			)

			return err
		}
	}
}

// ErrorHandler returns an Echo error handler with logging
func ErrorHandler(logger *Logger) echo.HTTPErrorHandler {
	return func(err error, c echo.Context) {
		code := 500
		message := "Internal Server Error"

		if he, ok := err.(*echo.HTTPError); ok {
			code = he.Code
			if msg, ok := he.Message.(string); ok {
				message = msg
			}
		}

		logger.Error("http error",
			"code", code,
			"message", message,
			"path", c.Request().URL.Path,
			"method", c.Request().Method,
		)

		// Send error response
		if !c.Response().Committed {
			if c.Request().Method == "HEAD" {
				c.NoContent(code)
			} else {
				c.JSON(code, map[string]interface{}{
					"error": message,
					"code":  code,
				})
			}
		}
	}
}
