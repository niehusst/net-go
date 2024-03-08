package middleware

import (
	"net-go/server/backend/apperrors"
	"net-go/server/backend/handler/cookies"
	"net-go/server/backend/handler/router/endpoints"

	"github.com/gin-gonic/gin"
)

// wrapped for typing
func AuthUser(handler endpoints.RouteHandler) gin.HandlerFunc {
	return func(c *gin.Context) {
		// extract auth cookie
		cookie, err := cookies.GetAuthCookieFromRequest(c)
		if err != nil {
			// abort continuation of request handling
			unauthErr := apperrors.NewUnauthorized()
			c.AbortWithStatusJSON(unauthErr.Status(), gin.H{
				"error": unauthErr.Error(),
			})
			return
		}

		userId, sessToken, err := cookies.DeconstructAuthCookie(cookie)
		if err != nil {
			// del expired/bad auth cookie
			cookies.DeleteAuthCookiesInResponse(c)

			unauthErr := apperrors.NewUnauthorized()
			c.AbortWithStatusJSON(unauthErr.Status(), gin.H{
				"error": unauthErr.Error(),
			})
			return
		}

		// get/auth the user
		user, err := handler.Provider.UserService.Get(c, uint(userId))
		if err != nil || sessToken != user.SessionToken {
			// del expired/bad auth cookie
			cookies.DeleteAuthCookiesInResponse(c)

			unauthErr := apperrors.NewUnauthorized()
			c.AbortWithStatusJSON(unauthErr.Status(), gin.H{
				"error": unauthErr.Error(),
			})
			return
		}

		// save the user for later use
		c.Set("user", user)

		// proceed to next req handler
		c.Next()
	}
}
