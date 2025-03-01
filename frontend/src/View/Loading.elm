module View.Loading exposing (viewLoading)

import Html exposing (..)
import Html.Attributes exposing (..)

viewLoading : String -> Html msg
viewLoading message =
    div [ class "flex flex-col items-center justify-center" ]
        [ p [] [ text message ]
        , img [ src "/static/resources/loading-wheel.svg" ] []
        ]
