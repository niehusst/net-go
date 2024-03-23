module API.Games exposing (getGame)

import Http


prefix =
    "/api/games"


{-| Fetches a game from backend by path param ID.
gameId - ID of game to fetch
msgType - the Msg type to trigger on completion via Cmd
-}
getGame : String -> (Result Http.Error () -> msg) -> Cmd msg
getGame gameId msgType =
    Http.get
        { url = prefix ++ "/" ++ gameId
        , expect = Http.expectWhatever msgType
        }
