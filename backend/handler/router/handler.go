package router

import (
	"net-go/server/backend/handler/provider"
)

type RouteHandler struct {
	p provider.Provider
}

func NewRouteHandler(p provider.Provider) RouteHandler {
	return RouteHandler{
		p: p,
	}
}
