module View.Error exposing (viewErrorBanner, viewHttpError)

import Error exposing (stringFromHttpError)
import Html exposing (..)
import Html.Attributes exposing (..)
import Http


viewHttpError : Maybe Http.Error -> Html msg
viewHttpError maybeHttpError =
    case maybeHttpError of
        Just httpError ->
            let
                errMsg =
                    stringFromHttpError httpError
            in
            viewErrorBanner errMsg

        Nothing ->
            text ""


viewErrorBanner : String -> Html msg
viewErrorBanner message =
    div
        [ class "w-full bg-red-300 rounded px-4 p-2" ]
        [ p [ class "font-bold" ]
            [ text message ]
        ]
