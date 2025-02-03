port module ScoringPorts exposing (decodeGameFromValue, sendScoreGame, returnScoreGame, receiveSentGame, receiveReturnedGame)

import Model.Game as Game
import Json.Decode exposing (Error(..), Value, decodeValue)

decodeGameFromValue : Value -> Result Error Game.Game
decodeGameFromValue value =
    decodeValue Game.gameDecoder value


port sendScoreGame : Value -> Cmd msg

port receiveSentGame : (Value -> msg) -> Sub msg

port returnScoreGame : Value -> Cmd msg

port receiveReturnedGame : (Value -> msg) -> Sub msg
