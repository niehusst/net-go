package subscriptions

import (
	"net-go/server/backend/model"
)

type GameListener = chan model.Game
type GameSubscriptions = map[uint]GameListener
