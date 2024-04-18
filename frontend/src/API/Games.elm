module API.Games exposing (getGame)

import Http
import RemoteData
import Model.Game exposing (gameDecoder)

prefix =
    "/api/games"


{-| Fetches a game from backend by path param ID.
gameId - ID of game to fetch
msgType - the Msg type to trigger on completion via Cmd
-}
getGame : String -> (RemoteData.WebData Model.Game.Game -> msg) -> Cmd msg
getGame gameId msgType =
    -- TODO: json encoding for returned struct
    Http.get
        { url = prefix ++ "/" ++ gameId
        , expect =
            gameDecoder
                |> Http.expectJson (RemoteData.fromResult >> msgType)
        }
