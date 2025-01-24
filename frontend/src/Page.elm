module Page exposing (viewFooter, viewHeader)

-- yoinked from https://github.com/rtfeldman/elm-spa-example/blob/master/src/Page.elm

import Html exposing (Html, a, button, div, footer, i, li, nav, p, span, text, ul)
import Html.Attributes exposing (class, classList, href, style)
import Html.Events exposing (onClick)
import Route exposing (Route, routeToString)
import Session exposing (Session(..))


viewHeader : Session -> Html msg
viewHeader session =
    nav [ class "w-screen bg-primary p-3" ]
        [ div [ class "flex flex-row justify-between items-center" ]
            [ a [ class "brand-logo", href (routeToString Route.Home) ]
                [ text "net-go" ]
            , ul [ class "flex flex-row gap-6 text-accent3 text-lg" ] <|
                viewMenu session
            ]
        ]


viewMenu : Session -> List (Html msg)
viewMenu session =
    case session of
        Session.LoggedIn _ ->
            [ linkTo Route.Logout [ text "Sign out" ]
            ]

        Session.LoggedOut _ ->
            [ linkTo Route.SignIn [ text "Sign in" ]
            , linkTo Route.SignUp [ text "Sign up" ]
            ]


viewFooter : Html msg
viewFooter =
    footer [ class "w-screen flex flex-col items-center justify-center bg-accent3 py-12 text-white" ]
        [ div []
            [ a
                [ class "logo-font pr-4 text-sm"
                , href (routeToString Route.Home)
                ]
                [ text "net-go" ]
            , span [ class "text-xs" ]
                [ text "Code & design licensed under GPL-3.0" ]
            ]
        , a
            [ class "text-xs underline"
            , href "https://github.com/niehusst/net-go"
            ]
            [ text "Source available on GitHub" ]
        ]


linkTo : Route -> List (Html msg) -> Html msg
linkTo route linkContent =
    li [ classList [ ( "nav-item", True ) ] ]
        [ a [ class "nav-link hover:underline font-semibold", href (routeToString route) ] linkContent ]
