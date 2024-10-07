package endpoints

import (
	"net-go/server/backend/handler/provider"
)

type RouteHandler struct {
	Provider provider.Provider
}

func NewRouteHandler(p provider.Provider) RouteHandler {
	return RouteHandler{
		Provider: p,
	}
}
