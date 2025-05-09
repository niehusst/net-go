module API.Accounts exposing (AuthRequestData, AuthResponseData, doLogout, sendSigninReq, sendSignupReq)

import Error exposing (CustomWebData, HttpErrorResponse, expectJsonWithError)
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline
import Json.Encode as Encode
import RemoteData exposing (RemoteData)


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


sendSigninReq : AuthRequestData r -> (CustomWebData AuthResponseData -> msg) -> Cmd msg
sendSigninReq reqData receiveMsg =
    Http.post
        { url = prefix ++ "/signin"
        , body = Http.jsonBody (authEncoder reqData)
        , expect =
            authDecoder
                |> expectJsonWithError (RemoteData.fromResult >> receiveMsg)
        }


sendSignupReq : AuthRequestData r -> (CustomWebData AuthResponseData -> msg) -> Cmd msg
sendSignupReq reqData receiveMsg =
    Http.post
        { url = prefix ++ "/signup"
        , body = Http.jsonBody (authEncoder reqData)
        , expect =
            authDecoder
                |> expectJsonWithError (RemoteData.fromResult >> receiveMsg)
        }
