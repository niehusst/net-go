module API.Games exposing (CreateGameResponse, createGame, getGame)

import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode
import Model.Game exposing (Game, gameDecoder, gameEncoder)
import RemoteData


prefix =
    "/api/games"


type alias CreateGameResponse =
    { uid : Int }


decodeCreateGameResponse : Decoder CreateGameResponse
decodeCreateGameResponse =
    Decode.succeed CreateGameResponse
        |> required "uid" Decode.int


{-| Fetches a game from backend by path param ID.
gameId - ID of game to fetch
msgType - the Msg type to trigger on completion via Cmd
-}
getGame : String -> (RemoteData.WebData Model.Game.Game -> msg) -> Cmd msg
getGame gameId msgType =
    let
        respDecoder : Decoder Model.Game.Game
        respDecoder =
            Decode.field "game" gameDecoder
    in
    Http.get
        { url = prefix ++ "/" ++ gameId
        , expect =
            respDecoder
                |> Http.expectJson (RemoteData.fromResult >> msgType)
        }


{-| Create the passed game on the backend.
game - Game struct to create
msgType - the Msg to trigger on completion via Cmd
-}
createGame : Game -> (Result Http.Error CreateGameResponse -> msg) -> Cmd msg
createGame game msgType =
    let
        body =
            Json.Encode.object
                [ ( "game", gameEncoder game ) ]
    in
    Http.post
        { url = prefix ++ "/"
        , body = Http.jsonBody body
        , expect = Http.expectJson msgType decodeCreateGameResponse
        }
