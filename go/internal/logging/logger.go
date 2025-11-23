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
	prettyPrint bool
}

// NewLogger creates a new structured logger
// In development (when PORT=3001 or GO_ENV=development), uses pretty printing
func NewLogger() *Logger {
	// Determine if we're in development mode
	prettyPrint := false
	if os.Getenv("GO_ENV") == "development" || os.Getenv("PORT") == "3001" || os.Getenv("PORT") == "" {
		prettyPrint = true
	}

	return &Logger{
		Logger:      log.New(os.Stdout, "", 0),
		prettyPrint: prettyPrint,
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
	timestamp := time.Now().Format("15:04:05")

	if l.prettyPrint {
		// Pretty colored output for development
		levelColor := getColorForLevel(level)
		output := fmt.Sprintf("\033[90m%s\033[0m %s%-5s\033[0m %s", timestamp, levelColor, level, msg)

		if len(fields) > 0 {
			output += " \033[90m|"
			for i := 0; i < len(fields); i += 2 {
				if i+1 < len(fields) {
					output += fmt.Sprintf(" %v=%v", fields[i], fields[i+1])
				}
			}
			output += "\033[0m"
		}

		l.Println(output)
	} else {
		// Structured output for production
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
}

// getColorForLevel returns ANSI color codes for different log levels
func getColorForLevel(level string) string {
	switch level {
	case "ERROR":
		return "\033[31m" // Red
	case "WARN":
		return "\033[33m" // Yellow
	case "INFO":
		return "\033[32m" // Green
	case "DEBUG":
		return "\033[36m" // Cyan
	default:
		return "\033[0m" // Reset
	}
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
