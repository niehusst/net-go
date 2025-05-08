module Page.NotFound exposing (view)

import Html exposing (..)
import Html.Attributes exposing (href, class)
import Route exposing (Route, routeToString)



-- VIEW --


view : Html msg
view =
    div [ class "flex flex-col items-center justify-center gap-3 my-6" ]
        [ h1 [ class "text-3xl font-black" ] [ text "404" ]
        , h3 [] [ text "Oops! This page could not be found." ]
        , a [ href (routeToString Route.Home) ]
            [ button [ class "btn" ] [ text "Return to home page" ] ]
        ]
