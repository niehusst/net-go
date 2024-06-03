module API.Games exposing (CreateGameResponse, createGame, getGame)

import Http
import Json.Decode as Decode exposing (Decoder, string)
import Json.Decode.Pipeline exposing (optional, required)
import Model.Game exposing (Game, gameDecoder, gameEncoder)
import RemoteData


prefix =
    "/api/games"


type alias CreateGameResponse =
    { uid : String }


decodeCreateGameResponse : Decoder CreateGameResponse
decodeCreateGameResponse =
    Decode.succeed CreateGameResponse
        |> required "uid" string


{-| Fetches a game from backend by path param ID.
gameId - ID of game to fetch
msgType - the Msg type to trigger on completion via Cmd
-}
getGame : String -> (RemoteData.WebData Model.Game.Game -> msg) -> Cmd msg
getGame gameId msgType =
    Http.get
        { url = prefix ++ "/" ++ gameId
        , expect =
            gameDecoder
                |> Http.expectJson (RemoteData.fromResult >> msgType)
        }


{-| Create the passed game on the backend.
game - Game struct to create
msgType - the Msg to trigger on completion via Cmd
-}
createGame : Game -> (Result Http.Error CreateGameResponse -> msg) -> Cmd msg
createGame game msgType =
    Http.post
        { url = prefix ++ "/"
        , body = Http.jsonBody (gameEncoder game)
        , expect = Http.expectJson msgType decodeCreateGameResponse
        }
