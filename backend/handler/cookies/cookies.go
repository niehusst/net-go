package cookies

import (
	"fmt"
	"github.com/gin-gonic/gin"
	"net-go/server/backend/constants"
	"net-go/server/backend/model"
	"strconv"
	"strings"
)

const AuthCookieKey = "ngo_auth"
const ViewerDataCookieKey = "ngo_viewer_data"

func createAuthCookie(userId uint, sessionToken string) string {
	return strconv.FormatUint(uint64(userId), 10) + "::" + sessionToken
}

func DeconstructAuthCookie(cookie string) (uint64, string, error) {
	// set defaults for err returns
	var id uint64 = 0
	sessToken := ""

	parts := strings.Split(cookie, "::")
	if len(parts) != 2 {
		return id, sessToken, fmt.Errorf("Auth cookie was not a valid. Expected 2 parts, got %d", len(parts))
	}

	id, err := strconv.ParseUint(parts[0], 10, 64)
	if err != nil {
		return id, sessToken, fmt.Errorf("Expected user ID to be uint, got %s", parts[0])
	}

	sessToken = parts[1]
	return id, sessToken, nil
}

/**
 * Save an auth cookie to validate `user` to the gin context response.
 */
func SetAuthCookiesInResponse(user model.User, c *gin.Context) {
	oneMonthSeconds := 2592000
	// actual auth cookie
	c.SetCookie(
		AuthCookieKey,
		createAuthCookie(user.ID, user.SessionToken),
		oneMonthSeconds,
		"/",
		constants.GetDomain(),
		false,
		true, // httpOnly
	)
	// viewer data cookie for client side to check whether or not to make auth test requests
	c.SetCookie(
		ViewerDataCookieKey,
		fmt.Sprintf("{\"id\":%d,\"username\":\"%s\"}", user.ID, user.Username),
		oneMonthSeconds,
		"/",
		constants.GetDomain(),
		false,
		false, // httpOnly
	)
}

func DeleteAuthCookiesInResponse(c *gin.Context) {
	deleteNow := -1
	// actual auth cookie
	c.SetCookie(
		AuthCookieKey,
		"",
		deleteNow,
		"/",
		constants.GetDomain(),
		false,
		true, // httpOnly
	)
	// flag cookie for client side to check whether or not to make auth test requests
	c.SetCookie(
		ViewerDataCookieKey,
		"",
		deleteNow,
		"/",
		constants.GetDomain(),
		false,
		false, // httpOnly
	)
}

/**
 * returns an error if the auth cookie was not set.
 */
func GetAuthCookieFromRequest(c *gin.Context) (string, error) {
	value, err := c.Cookie(AuthCookieKey)
	return value, err
}
