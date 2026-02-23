package handlers

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"mime"
	"mime/multipart"
	"os"
	"path/filepath"
	"strings"
	"upload-lambda/internal/services"

	"github.com/aws/aws-lambda-go/events"
)

// LambdaHandler handles AWS Lambda requests
type LambdaHandler struct {
	service services.ExpenseService
}

// NewLambdaHandler creates a new Lambda handler
func NewLambdaHandler(service services.ExpenseService) *LambdaHandler {
	return &LambdaHandler{
		service: service,
	}
}

// Handle processes Lambda events
func (h *LambdaHandler) Handle(ctx context.Context, request events.APIGatewayV2HTTPRequest) (events.APIGatewayV2HTTPResponse, error) {
	// Validate Content-Type
	contentType := request.Headers["content-type"]
	if !strings.Contains(contentType, "multipart/form-data") {
		return errorResponse(400, "Content-Type must be multipart/form-data"), nil
	}

	// Decode body
	var bodyBytes []byte
	if request.IsBase64Encoded {
		decoded, err := base64.StdEncoding.DecodeString(request.Body)
		if err != nil {
			return errorResponse(400, "Failed to decode base64 body"), nil
		}
		bodyBytes = decoded
	} else {
		bodyBytes = []byte(request.Body)
	}

	// Parse multipart form
	_, params, err := mime.ParseMediaType(contentType)
	if err != nil {
		return errorResponse(400, "Failed to parse Content-Type"), nil
	}

	boundary, ok := params["boundary"]
	if !ok {
		return errorResponse(400, "No boundary in Content-Type"), nil
	}

	reader := multipart.NewReader(bytes.NewReader(bodyBytes), boundary)

	var audioFilePath string

	// Process multipart parts
	for {
		part, err := reader.NextPart()
		if err == io.EOF {
			break
		}
		if err != nil {
			return errorResponse(400, "Failed to read multipart data"), nil
		}

		fieldName := part.FormName()

		if fieldName == "audio" {
			filename := part.FileName()
			if filename == "" {
				part.Close()
				continue
			}

			// Sanitize filename
			safeName := filepath.Base(filename)
			savePath := filepath.Join("/tmp", safeName)

			// Create file
			file, err := os.Create(savePath)
			if err != nil {
				part.Close()
				return errorResponse(500, "Failed to create file"), nil
			}

			// Copy file content
			_, err = io.Copy(file, part)
			file.Close()
			part.Close()

			if err != nil {
				return errorResponse(500, "Failed to save file"), nil
			}

			audioFilePath = savePath
		} else {
			part.Close()
		}
	}

	// Check if file was uploaded
	if audioFilePath == "" {
		return errorResponse(400, "No audio file provided"), nil
	}

	// Ensure cleanup
	defer os.Remove(audioFilePath)

	// Process expenses using service (may be multiple)
	expenses, err := h.service.ProcessAudioExpense(ctx, audioFilePath)
	if err != nil {
		return errorResponse(500, fmt.Sprintf("Failed to process expenses: %v", err)), nil
	}

	// Return success response
	responseBody, err := json.Marshal(expenses)
	if err != nil {
		return errorResponse(500, "Failed to marshal response"), nil
	}

	return events.APIGatewayV2HTTPResponse{
		StatusCode: 200,
		Body:       string(responseBody),
		Headers: map[string]string{
			"Content-Type": "application/json",
		},
	}, nil
}

func errorResponse(statusCode int, message string) events.APIGatewayV2HTTPResponse {
	errorResp := map[string]string{"error": message}
	body, _ := json.Marshal(errorResp)

	return events.APIGatewayV2HTTPResponse{
		StatusCode: statusCode,
		Body:       string(body),
		Headers: map[string]string{
			"Content-Type": "application/json",
		},
	}
}
