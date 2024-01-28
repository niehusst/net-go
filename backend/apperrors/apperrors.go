package apperrors

import (
	"errors"
	"fmt"
	"net/http"
)

// craft our own enum types since go doesnt have those

// error type
type Type string

const (
	Authorization Type = "AUTHORIZATION" // Authentication Failures -
	BadRequest    Type = "BADREQUEST"    // Validation errors / BadInput
	Conflict      Type = "CONFLICT"      // Already exists (eg, create account with existent username) - 409
	Internal      Type = "INTERNAL"      // Server (500) and fallback errors
	NotFound      Type = "NOTFOUND"      // For not finding resource
)

// our custom error type
type Error struct {
	Type    Type   `json:"type"`
	Message string `json:"message"`
}

func (e *Error) Error() string {
	return e.Message
}

// map from custom error types to standard http statuses
func (e *Error) Status() int {
	switch e.Type {
	case Authorization:
		return http.StatusUnauthorized
	case BadRequest:
		return http.StatusBadRequest
	case Conflict:
		return http.StatusConflict
	case Internal:
		return http.StatusInternalServerError
	case NotFound:
		return http.StatusNotFound
	default:
		return http.StatusInternalServerError
	}
}

// Try cast error as Error and return status code
func Status(err error) int {
	var e *Error
	if errors.As(err, &e) {
		return e.Status()
	}
	return http.StatusInternalServerError
}

/*
 * Error factories
 */

// 401
func NewAuthorization(reason string) *Error {
	return &Error{
		Type:    Authorization,
		Message: reason,
	}
}

// NewBadRequest to create 400 errors (validation, for example)
func NewBadRequest(reason string) *Error {
	return &Error{
		Type:    BadRequest,
		Message: fmt.Sprintf("Bad request. Reason: %v", reason),
	}
}

// NewConflict to create an error for 409
func NewConflict(name string, value string) *Error {
	return &Error{
		Type:    Conflict,
		Message: fmt.Sprintf("resource: %v with value: %v already exists", name, value),
	}
}

// NewInternal for 500 errors and unknown errors
func NewInternal() *Error {
	return &Error{
		Type:    Internal,
		Message: fmt.Sprintf("Internal server error."),
	}
}

// NewNotFound to create an error for 404
func NewNotFound(name string, value string) *Error {
	return &Error{
		Type:    NotFound,
		Message: fmt.Sprintf("resource: %v with value: %v not found", name, value),
	}
}
