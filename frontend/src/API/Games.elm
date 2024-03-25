module API.Games exposing (getGame)

import Http
import RemoteData


prefix =
    "/api/games"


{-| Fetches a game from backend by path param ID.
gameId - ID of game to fetch
msgType - the Msg type to trigger on completion via Cmd
-}
getGame : String -> (Result Http.Error () -> msg) -> Cmd msg
getGame gameId msgType =
    -- TODO: Webdata instead of Result
    -- TODO: json encoding for returned struct
    Http.get
        { url = prefix ++ "/" ++ gameId
        , expect = Http.expectWhatever msgType
        }
