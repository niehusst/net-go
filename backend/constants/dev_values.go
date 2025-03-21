package constants

import (
	"github.com/joho/godotenv"
	"log"
	"os"
)

func LoadEnv() error {
	err := godotenv.Load()
	if err != nil {
		log.Fatal("Error loading .env file")
	}
	return err
}

func getEnvWithDefault(key string, defaultVal string) string {
	envVal := os.Getenv(key)
	if envVal == "" {
		return defaultVal
	}
	return envVal
}

func GetDevMode() bool {
	return getEnvWithDefault("DEV_MODE", "false") == "true"
}

func GetDomain() string {
	// TODO: swap localhost here w/ real server domain name
	return getEnvWithDefault("DOMAIN", "localhost")
}

func GetPort() string {
	return getEnvWithDefault("PORT", "8080")
}

func GetDatabaseURL() string {
	return getEnvWithDefault("DATABASE_URL", "netgo.gorm.db")
}
