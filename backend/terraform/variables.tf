variable "aws_region" {
  default = "us-east-1"
}

variable "openai_api_key" {
  description = "OpenAI API Key for Whisper and GPT"
  type        = string
  sensitive   = true
}

variable "db_url" {
  description = "PostgreSQL connection string (format: postgres://user:password@host:port/database?sslmode=require)"
  type        = string
  sensitive   = true
}