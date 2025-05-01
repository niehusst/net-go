module API.Games exposing (CreateGameResponse, createGame, deleteGame, getGame, listGamesByUser, updateGame)

import Error exposing (CustomWebData, HttpErrorResponse, expectJsonWithError)
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
getGame : String -> (CustomWebData Model.Game.Game -> msg) -> Cmd msg
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
                |> expectJsonWithError (RemoteData.fromResult >> msgType)
        }


{-| Fetch the list of all games that the requesting authed user is a member of.
(either as the black player or the white player)

msgType - the Msg type to trigger on completion via Cmd

-}
listGamesByUser : (CustomWebData (List Model.Game.Game) -> msg) -> Cmd msg
listGamesByUser msgType =
    let
        respDecoder : Decoder (List Model.Game.Game)
        respDecoder =
            Decode.field "games" (Decode.list gameDecoder)
    in
    Http.get
        { url = prefix
        , expect =
            respDecoder
                |> expectJsonWithError (RemoteData.fromResult >> msgType)
        }


{-| Create the passed game on the backend to store it in the DB.
game - Game struct to create
msgType - the Msg to trigger on completion via Cmd
-}
createGame : Game -> (Result HttpErrorResponse CreateGameResponse -> msg) -> Cmd msg
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
        , expect = expectJsonWithError msgType decodeResponse
        }


{-| Update the stored Game in the DB with the pass value.
gameId - ID of the DB Game table row to update
game - new value of Game struct to update DB with
msgType - the Msg to trigger on completion via Cmd
-}
updateGame : String -> Game -> (Result HttpErrorResponse Model.Game.Game -> msg) -> Cmd msg
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
        , expect = expectJsonWithError msgType respDecoder
        }


{-| Deletes a game from backend by path param ID. Requesting user must be
a player in the game requested for deletion.

gameId - ID of game to delete
msgType - the Msg type to trigger on completion via Cmd

-}
deleteGame : String -> (Result Http.Error () -> msg) -> Cmd msg
deleteGame gameId msgType =
    Http.request
        { url = prefix ++ "/" ++ gameId
        , method = "DELETE"
        , headers = []
        , body = Http.emptyBody
        , expect =
            Http.expectWhatever msgType
        , timeout = Nothing
        , tracker = Nothing
        }
