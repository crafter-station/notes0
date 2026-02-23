package handlers

import (
	"bytes"
	"context"
	"encoding/base64"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"upload-lambda/internal/services"

	"github.com/aws/aws-lambda-go/events"
)

// LambdaHandler handles AWS Lambda requests by delegating to the HTTP router
type LambdaHandler struct {
	router http.Handler
}

// NewLambdaHandler creates a new Lambda handler that uses the HTTP router
func NewLambdaHandler(service services.ExpenseService) *LambdaHandler {
	return &LambdaHandler{
		router: NewRouter(service),
	}
}

// Handle processes Lambda events by converting them to HTTP requests
func (h *LambdaHandler) Handle(ctx context.Context, request events.APIGatewayV2HTTPRequest) (events.APIGatewayV2HTTPResponse, error) {
	// Get path and method
	path := request.RawPath
	if path == "" {
		path = request.RequestContext.HTTP.Path
	}
	method := request.RequestContext.HTTP.Method

	// Decode body if base64 encoded
	var bodyReader io.Reader
	if request.IsBase64Encoded {
		decoded, err := base64.StdEncoding.DecodeString(request.Body)
		if err != nil {
			return errorResponse(400, "Failed to decode base64 body"), nil
		}
		bodyReader = bytes.NewReader(decoded)
	} else {
		bodyReader = strings.NewReader(request.Body)
	}

	// Create HTTP request
	httpReq, err := http.NewRequestWithContext(ctx, method, path, bodyReader)
	if err != nil {
		return errorResponse(500, "Failed to create HTTP request"), nil
	}

	// Copy headers
	for key, value := range request.Headers {
		httpReq.Header.Set(key, value)
	}

	// Copy query parameters
	q := httpReq.URL.Query()
	for key, value := range request.QueryStringParameters {
		q.Set(key, value)
	}
	httpReq.URL.RawQuery = q.Encode()

	// Create response recorder
	recorder := httptest.NewRecorder()

	// Delegate to router
	h.router.ServeHTTP(recorder, httpReq)

	// Convert HTTP response to API Gateway response
	result := recorder.Result()
	defer result.Body.Close()

	responseBody, err := io.ReadAll(result.Body)
	if err != nil {
		return errorResponse(500, "Failed to read response body"), nil
	}

	// Copy headers
	headers := make(map[string]string)
	for key, values := range result.Header {
		if len(values) > 0 {
			headers[key] = values[0]
		}
	}

	return events.APIGatewayV2HTTPResponse{
		StatusCode: result.StatusCode,
		Headers:    headers,
		Body:       string(responseBody),
	}, nil
}

func errorResponse(statusCode int, message string) events.APIGatewayV2HTTPResponse {
	body := `{"error":"` + message + `"}`
	return events.APIGatewayV2HTTPResponse{
		StatusCode: statusCode,
		Body:       body,
		Headers: map[string]string{
			"Content-Type": "application/json",
		},
	}
}
