module Error exposing (CustomWebData, HttpErrorResponse, expectJsonWithError, newErrorResp, stringFromHttpError)

import Http
import Json.Decode as Decode exposing (Decoder)
import RemoteData exposing (RemoteData)


type alias CustomWebData a =
    RemoteData HttpErrorResponse a


type alias HttpErrorResponse =
    { httpError : Http.Error
    , errorMessage : Maybe String
    }


newErrorResp : Http.Error -> Maybe String -> HttpErrorResponse
newErrorResp httpError message =
    { httpError = httpError
    , errorMessage = message
    }


errorDecoder : Decoder String
errorDecoder =
    Decode.field "error" Decode.string


expectJsonWithError : (Result HttpErrorResponse a -> msg) -> Decoder a -> Http.Expect msg
expectJsonWithError toMsg decoder =
    Http.expectStringResponse toMsg <|
        \response ->
            case response of
                Http.BadUrl_ url ->
                    Err <| newErrorResp (Http.BadUrl url) Nothing

                Http.Timeout_ ->
                    Err <| newErrorResp Http.Timeout Nothing

                Http.NetworkError_ ->
                    Err <| newErrorResp Http.NetworkError Nothing

                Http.BadStatus_ metadata body ->
                    let
                        serverMessage =
                            case Decode.decodeString errorDecoder body of
                                Ok value ->
                                    Just value

                                Err err ->
                                    Nothing
                    in
                    Err <| newErrorResp (Http.BadStatus metadata.statusCode) serverMessage

                Http.GoodStatus_ metadata body ->
                    case Decode.decodeString decoder body of
                        Ok value ->
                            Ok value

                        Err err ->
                            Err <| newErrorResp (Http.BadBody (Decode.errorToString err)) Nothing


stringFromHttpError : HttpErrorResponse -> String
stringFromHttpError error =
    case error.httpError of
        Http.BadUrl msg ->
            "Bad url: " ++ msg

        Http.Timeout ->
            "Server took too long to repond; please try again later."

        Http.NetworkError ->
            "Network error; please try again later."

        Http.BadStatus errCode ->
            let
                msg =
                    case error.errorMessage of
                        Just err ->
                            err

                        Nothing ->
                            case errCode of
                                504 ->
                                    "Server took too long to repond; please try again later."

                                500 ->
                                    "Internal server error."

                                400 ->
                                    "Submitted data was invalid."

                                401 ->
                                    "Authentication failure. Please sign in."

                                403 ->
                                    "Authentication failure. You're not allowed to do that."

                                404 ->
                                    "Unable to find that data."

                                _ ->
                                    "Oops! An error occured."
            in
            String.fromInt errCode ++ " ERROR: " ++ msg

        Http.BadBody msg ->
            "Response could not be parsed: " ++ msg
