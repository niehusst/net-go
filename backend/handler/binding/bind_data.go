package binding

import (
	"fmt"
	"github.com/gin-gonic/gin"
	"github.com/go-playground/validator/v10"
	"net-go/server/backend/apperrors"
	"net-go/server/backend/logger"
)

/* helper utility for network data binding error handling */

// used to help extract validation errors
type invalidArgument struct {
	Field string `json:"field"`
	Value string `json:"value"`
	Tag   string `json:"tag"`
	Param string `json:"param"`
}

/*
 * Binds network request data to a request go struct.
 * On bind failure, automatically sends a json response via gin.
 *
 * @param c - context that will deliver the request data
 * @param req - any request data struct
 * @return - whether or not data was successfully bound
 */
func BindData(c *gin.Context, req any) bool {
	// attempt bind json data to struct
	if err := c.ShouldBindJSON(req); err != nil {
		logger.Debug("Error binding data: %+v\n", err)

		if errs, ok := err.(validator.ValidationErrors); ok {
			var invalidArgs []invalidArgument

			for _, error := range errs {
				invalidArgs = append(invalidArgs, invalidArgument{
					error.Field(),
					fmt.Sprintf("%v", error.Value()),
					error.Tag(),
					error.Param(),
				})
			}

			badReq := apperrors.NewBadRequest("Invalid request parameters")

			c.JSON(badReq.Status(), gin.H{
				"error":       badReq,
				"invalidArgs": invalidArgs,
			})
			return false
		}

		// if we aren't able to properly extract validation errors,
		// we'll fallback and return an internal server error
		fallBack := apperrors.NewInternal()

		c.JSON(fallBack.Status(), gin.H{"error": fallBack})
		return false
	}

	// no errors! data bound successfully
	return true
}
