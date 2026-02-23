package services

import (
	"context"
	"log"
	"time"
	"upload-lambda/internal/models"
	"upload-lambda/internal/repositories"

	"github.com/google/uuid"
)

// ExpenseService defines the interface for expense business logic
type ExpenseService interface {
	ProcessAudioExpense(ctx context.Context, audioPath string, purchasedAt time.Time) ([]*models.Expense, error)
}

type expenseService struct {
	openaiRepo  repositories.OpenAIRepository
	expenseRepo repositories.ExpenseRepository
}

// NewExpenseService creates a new expense service
func NewExpenseService(
	openaiRepo repositories.OpenAIRepository,
	expenseRepo repositories.ExpenseRepository,
) ExpenseService {
	return &expenseService{
		openaiRepo:  openaiRepo,
		expenseRepo: expenseRepo,
	}
}

func (s *expenseService) ProcessAudioExpense(ctx context.Context, audioPath string, purchasedAt time.Time) ([]*models.Expense, error) {
	// Step 1: Transcribe audio
	log.Printf("Transcribing audio: %s", audioPath)
	transcription, err := s.openaiRepo.TranscribeAudio(ctx, audioPath)
	if err != nil {
		log.Printf("Transcription error: %v", err)
		return nil, err
	}
	log.Printf("Transcription: %s", transcription)

	// Step 2: Extract expense data (may be multiple expenses)
	log.Printf("Extracting expense data from transcription")
	expensesData, err := s.openaiRepo.ExtractExpenseData(ctx, transcription)
	if err != nil {
		log.Printf("Extraction error: %v", err)
		return nil, err
	}
	log.Printf("Extracted %d expense(s)", len(expensesData))

	// Step 3: Create and save each expense
	var expenses []*models.Expense
	for i, data := range expensesData {
		// Default unit to "u" if not specified
		unit := data.Unit
		if unit == "" {
			unit = "u"
		}

		log.Printf("Processing expense %d/%d: unit_price=%.2f, quantity=%.2f, unit=%s, description=%s",
			i+1, len(expensesData), data.UnitPrice, data.Quantity, unit, data.Description)

		expense := &models.Expense{
			ID:          uuid.New().String(),
			UnitPrice:   data.UnitPrice,
			Quantity:    data.Quantity,
			Unit:        unit,
			Description: data.Description,
			PurchasedAt: purchasedAt,
			CreatedAt:   time.Now().UTC(),
		}

		// Step 4: Save to database
		log.Printf("Saving expense to database: %s", expense.ID)
		err = s.expenseRepo.Create(ctx, expense)
		if err != nil {
			log.Printf("Database error for expense %s: %v", expense.ID, err)
			return nil, err
		}

		expenses = append(expenses, expense)
		log.Printf("Expense created successfully: %s", expense.ID)
	}

	log.Printf("All %d expense(s) created successfully", len(expenses))
	return expenses, nil
}
