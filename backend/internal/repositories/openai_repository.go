package repositories

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"upload-lambda/internal/models"

	openai "github.com/sashabaranov/go-openai"
)

// OpenAIRepository defines the interface for OpenAI operations
type OpenAIRepository interface {
	TranscribeAudio(ctx context.Context, audioPath string) (string, error)
	ExtractExpenseData(ctx context.Context, transcription string) ([]models.ExpenseData, error)
}

type openAIRepo struct {
	client *openai.Client
}

// NewOpenAIRepository creates a new OpenAI repository
func NewOpenAIRepository(apiKey string) OpenAIRepository {
	return &openAIRepo{
		client: openai.NewClient(apiKey),
	}
}

func (r *openAIRepo) TranscribeAudio(ctx context.Context, audioPath string) (string, error) {
	file, err := os.Open(audioPath)
	if err != nil {
		return "", fmt.Errorf("failed to open audio file: %w", err)
	}
	defer file.Close()

	req := openai.AudioRequest{
		Model:    openai.Whisper1,
		FilePath: audioPath,
		Reader:   file,
	}

	resp, err := r.client.CreateTranscription(ctx, req)
	if err != nil {
		return "", fmt.Errorf("OpenAI transcription error: %w", err)
	}

	return resp.Text, nil
}

func (r *openAIRepo) ExtractExpenseData(ctx context.Context, transcription string) ([]models.ExpenseData, error) {
	prompt := fmt.Sprintf(`You are an expense parser. Extract ALL expenses from the Spanish text. There may be one or multiple expenses.

For EACH expense, extract:
- unit_price: the price per unit (decimal number)
- quantity: the quantity purchased (decimal number, use 1.0 if not specified)
- unit: the unit of measurement (string: "kg", "litro", "pasaje", "u" for generic units). Default to "u" if not specified
- description: short product description (string)

Text: "%s"

Respond ONLY with a valid JSON array of expenses in this exact format:
[
  {"unit_price": 0.0, "quantity": 0.0, "unit": "u", "description": ""},
  {"unit_price": 0.0, "quantity": 0.0, "unit": "kg", "description": ""}
]

If there's only one expense, still return an array with one element.
Return json only with json quotes`, transcription)

	req := openai.ChatCompletionRequest{
		Model: openai.GPT4,
		Messages: []openai.ChatCompletionMessage{
			{
				Role:    openai.ChatMessageRoleUser,
				Content: prompt,
			},
		},
		Temperature: 0.1,
	}

	resp, err := r.client.CreateChatCompletion(ctx, req)
	if err != nil {
		return nil, fmt.Errorf("OpenAI completion error: %w", err)
	}

	if len(resp.Choices) == 0 {
		return nil, fmt.Errorf("no response from GPT")
	}

	content := resp.Choices[0].Message.Content

	var expensesData []models.ExpenseData
	if err := json.Unmarshal([]byte(content), &expensesData); err != nil {
		return nil, fmt.Errorf("failed to parse GPT response: %w, response: %s", err, content)
	}

	if len(expensesData) == 0 {
		return nil, fmt.Errorf("no expenses found in transcription")
	}

	return expensesData, nil
}
