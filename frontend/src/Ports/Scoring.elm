port module Ports.Scoring exposing (decodeGameFromValue, receiveReturnedGame, receiveSentGame, returnScoreGame, sendScoreGame)

import Json.Decode exposing (Error(..), Value, decodeValue)
import Model.Game as Game


decodeGameFromValue : Value -> Result Error Game.Game
decodeGameFromValue value =
    decodeValue Game.gameDecoder value


port sendScoreGame : Value -> Cmd msg


port receiveSentGame : (Value -> msg) -> Sub msg


port returnScoreGame : Value -> Cmd msg


port receiveReturnedGame : (Value -> msg) -> Sub msg
