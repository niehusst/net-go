port module ScoringPorts exposing (sendScoreGame, receiveScoreGame)

import Model.Game as Game
import Json.Decode exposing (Error(..), Value, decodeValue)

decodeGameFromValue : Value -> Result Error Game.Game
decodeGameFromValue value =
    decodeValue Game.gameDecoder value

-- TODO: need 2 more? each needs a variant for subscription listening, and subscription sending

port sendScoreGame : Value -> Cmd msg

port receiveScoreGame : (Value -> msg) -> Sub msg
