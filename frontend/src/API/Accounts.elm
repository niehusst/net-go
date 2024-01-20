module API.Accounts exposing (doLogout)

import Http


prefix =
    "/api/accounts"


{-| Makes a signout request.
msgType - the Msg type to trigger on completion via Cmd
-}
doLogout : (Result Http.Error () -> msg) -> Cmd msg
doLogout msgType =
    Http.get
        { url = prefix ++ "/signout"
        , expect = Http.expectWhatever msgType
        }
