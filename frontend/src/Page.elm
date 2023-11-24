module Page exposing (viewFooter, viewHeader)

-- yoinked from https://github.com/rtfeldman/elm-spa-example/blob/master/src/Page.elm

import Html exposing (Html, a, button, div, footer, i, li, nav, p, span, text, ul)
import Html.Attributes exposing (class, classList, href, style)
import Html.Events exposing (onClick)
import Route exposing (Route, routeToString)
import Session exposing (Session(..))



-- TODO: redo all CSS


viewHeader : Session -> Html msg
viewHeader session =
    nav [ class "navbar navbar-light" ]
        [ div [ class "container" ]
            [ a [ class "navbar-brand", href (routeToString Route.Home) ]
                [ text "net-go" ]
            , ul [ class "nav navbar-nav pull-xs-right" ] <|
                viewMenu session
            ]
        ]


viewMenu : Session -> List (Html msg)
viewMenu session =
    case session of
        Session.LoggedIn _ ->
            [ text "logged in" -- TODO: kill this

            --, linkTo Route.Logout [ text "Sign out" ] -- TODO: really route?? or just make req?
            ]

        Session.LoggedOut _ ->
            [ linkTo Route.SignIn [ text "Sign in" ]
            , linkTo Route.SignUp [ text "Sign up" ]
            ]


viewFooter : Html msg
viewFooter =
    footer []
        [ div [ class "container" ]
            [ a [ class "logo-font", href (routeToString Route.Home) ] [ text "net-go" ]
            , span [ class "attribution" ]
                [ text "Code & design licensed under GPL-3.0"
                ]
            ]
        ]


linkTo : Route -> List (Html msg) -> Html msg
linkTo route linkContent =
    li [ classList [ ( "nav-item", True ) ] ]
        [ a [ class "nav-link", href (routeToString route) ] linkContent ]
