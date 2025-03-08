module API.Accounts exposing (doLogout, sendSigninReq, sendSignupReq, AuthRequestData, AuthResponseData)

import Http
import Json.Decode as Decode
import Json.Decode.Pipeline
import Json.Encode as Encode
import RemoteData exposing (RemoteData, WebData)


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

type alias AuthResponseData =
    { uid : Int
    , username : String
    }


type alias AuthRequestData r =
    { r
        | username : String
        , password : String
    }


authDecoder : Decode.Decoder AuthResponseData
authDecoder =
    Decode.succeed AuthResponseData
        |> Json.Decode.Pipeline.required "uid" Decode.int
        |> Json.Decode.Pipeline.required "username" Decode.string


authEncoder : AuthRequestData r -> Encode.Value
authEncoder reqData =
    Encode.object
        [ ( "username", Encode.string reqData.username )
        , ( "password", Encode.string reqData.password )
        ]


sendSigninReq : AuthRequestData r -> (RemoteData.WebData AuthResponseData -> msg) -> Cmd msg
sendSigninReq reqData receiveMsg =
    Http.post
        { url = prefix ++ "/signin"
        , body = Http.jsonBody (authEncoder reqData)
        , expect =
            authDecoder
                |> Http.expectJson (RemoteData.fromResult >> receiveMsg)
        }


sendSignupReq : AuthRequestData r -> (RemoteData.WebData AuthResponseData -> msg) -> Cmd msg
sendSignupReq reqData receiveMsg =
    Http.post
        { url = prefix ++ "/signup"
        , body = Http.jsonBody (authEncoder reqData)
        , expect =
            authDecoder
                |> Http.expectJson (RemoteData.fromResult >> receiveMsg)
        }
