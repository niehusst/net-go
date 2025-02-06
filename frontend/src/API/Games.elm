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


{-| Create the passed game on the backend to store it in the DB.
game - Game struct to create
msgType - the Msg to trigger on completion via Cmd
-}
createGame : Game -> (Result Http.Error CreateGameResponse -> msg) -> Cmd msg
createGame game msgType =
    let
        decodeResponse : Decoder CreateGameResponse
        decodeResponse =
            Decode.succeed CreateGameResponse
                |> required "uid" Decode.int
        body =
            Json.Encode.object
                [ ( "game", gameEncoder game ) ]
    in
    Http.post
        { url = prefix ++ "/"
        , body = Http.jsonBody body
        , expect = Http.expectJson msgType decodeResponse
        }

{-| Update the stored Game in the DB with the pass value.
gameId - ID of the DB Game table row to update
game - new value of Game struct to update DB with
msgType - the Msg to trigger on completion via Cmd
-}
updateGame : String -> Game -> (RemoteData.WebData Model.Game.Game -> msg) -> Cmd msg
updateGame gameId game msgType =
    let
        body =
            Json.Encode.object
                [ ( "game", gameEncoder game ) ]

        respDecoder : Decoder Model.Game.Game
        respDecoder =
            Decode.field "game" gameDecoder
    in
    Http.post
        { url = prefix ++ "/" ++ gameId
        , body = Http.jsonBody body
        , expect =
            respDecoder
                |> Http.expectJson (RemoteData.fromResult >> msgType)
        }
