module Error exposing (stringFromHttpError, viewHttpError)

import Html exposing (..)
import Html.Attributes exposing (style)
import Http


stringFromHttpError : Http.Error -> String
stringFromHttpError error =
    case error of
        Http.BadUrl msg ->
            "Bad url: " ++ msg

        Http.Timeout ->
            "Server took too long to repond; please try again later."

        Http.NetworkError ->
            "Network error; please try again later."

        Http.BadStatus errCode ->
            case errCode of
                500 ->
                    "Internal server error"

                401 ->
                    "Authentication failure. Please sign in."

                _ ->
                    "Oops! A " ++ String.fromInt errCode ++ " error occured."

        Http.BadBody msg ->
            "Bad body: " ++ msg


viewHttpError : Maybe Http.Error -> Html msg
viewHttpError maybeHttpError =
    case maybeHttpError of
        Just httpError ->
            let
                errMsg =
                    stringFromHttpError httpError
            in
            h2 [ style "color" "red" ] [ text errMsg ]

        Nothing ->
            text ""
