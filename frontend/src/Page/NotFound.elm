module Page.NotFound exposing (view)

import Html exposing (..)
import Html.Attributes exposing (href)
import Route exposing (Route, routeToString)



-- VIEW --


view : Html msg
view =
    div []
        [ h1 [] [ text "404" ]
        , h3 [] [ text "Oops! This page could not be found." ]
        , a [ href (routeToString Route.Home) ]
            [ button [] [ text "Return to home page" ] ]
        ]
