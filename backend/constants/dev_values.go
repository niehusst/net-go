package constants

import (
	"fmt"
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

func getEnvOrPanic(key string) string {
	envVal := os.Getenv(key)
	if envVal == "" {
		panic(fmt.Sprintf("Failed to find env var %s\n", key))
	}
	return envVal
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
	return getEnvWithDefault("DOMAIN", "playonlinego.xyz")
}

func GetPort() string {
	return getEnvWithDefault("PORT", "8080")
}

func GetDatabaseUserUsername() string {
	return getEnvOrPanic("DB_USER")
}

func GetDatabaseUserPassword() string {
	return getEnvOrPanic("DB_PASS")
}

func GetDatabaseName() string {
	return getEnvOrPanic("MARIADB_DATABASE")
}
