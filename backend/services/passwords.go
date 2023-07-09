package services

import (
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"golang.org/x/crypto/scrypt"
	"strings"
)

// create a salted and hashed string from a plaintext password
func hashPassword(password string) (string, error) {
	// example for making salt - https://play.golang.org/p/_Aw6WeWC42I
	salt := make([]byte, 32)
	_, err := rand.Read(salt)
	if err != nil {
		return "", err
	}

	// using recommended cost parameters from - https://godoc.org/golang.org/x/crypto/scrypt
	saltHash, err := scrypt.Key([]byte(password), salt, 32768, 8, 1, 32)
	if err != nil {
		return "", err
	}

	// hex-encode string w/ random salt appended to pw
	// (salt is appended so we can use it again in pw verification)
	hashedPassword := fmt.Sprintf("%s.%s", hex.EncodeToString(saltHash), hex.EncodeToString(salt))
	return hashedPassword, nil
}

// returns whether the 2 passwords match, once suppliedPassword
// is salted and hashed same way as storedPassword
func comparePasswords(storedPassword string, suppliedPassword string) (bool, error) {
	pwsalt := strings.Split(storedPassword, ".")

	// decode the random salt from stored pw
	salt, err := hex.DecodeString(pwsalt[1])
	if err != nil {
		return false, fmt.Errorf("Password verification failed")
	}

	// hash supplied pw using salt obtained from stored pw
	saltHash, err := scrypt.Key([]byte(suppliedPassword), salt, 32768, 8, 1, 32)

	return hex.EncodeToString(saltHash) == pwsalt[0], nil
}
