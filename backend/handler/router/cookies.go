package router

import (
	"github.com/gin-gonic/gin"
	"net-go/server/backend/constants"
	"net-go/server/backend/model"
	"strconv"
)

const AuthCookieKey = "ngo_auth"
const AuthCookieSetKey = "ngo_auth_set"

/**
 * Save an auth cookie to validate `user` to the gin context response.
 */
func SetAuthCookiesInResponse(user model.User, c *gin.Context) {
	// TODO: should implement sessions instead of putting pw hash in auth cookie
	oneMonthSeconds := 2592000
	// actual auth cookie
	c.SetCookie(
		AuthCookieKey,
		strconv.FormatUint(uint64(user.ID), 10)+"::"+user.Password,
		oneMonthSeconds,
		"/",
		constants.GetDomain(),
		false,
		true, // httpOnly
	)
	// flag cookie for client side to check whether or not to make auth test requests
	c.SetCookie(
		AuthCookieSetKey,
		"true",
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
		AuthCookieSetKey,
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
func GetAuthCookieFromResponse(c *gin.Context) (string, error) {
	value, err := c.Cookie(AuthCookieKey)
	return value, err
}
