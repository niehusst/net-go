package router

import (
	"github.com/gin-gonic/gin"
	"net-go/server/backend/constants"
	"net-go/server/backend/model"
	"strconv"
)

/**
 * Save an auth cookie to validate `user` to the gin context response.
 */
func SetAuthCookieInResponse(user model.User, c *gin.Context) {
	// TODO: should implement sessions instead of putting pw hash in auth cookie
	oneMonthSeconds := 2592000
	// actual auth cookie
	c.SetCookie(
		"ngo_auth",
		strconv.FormatUint(uint64(user.ID), 10)+"::"+user.Password,
		oneMonthSeconds,
		"/",
		constants.GetDomain(),
		false,
		true, // httpOnly
	)
	// flag cookie for client side to check whether or not to make auth test requests
	c.SetCookie(
		"ngo_auth_set",
		"yep",
		oneMonthSeconds,
		"/",
		constants.GetDomain(),
		false,
		false, // httpOnly
	)
}
