module Page.Header exposing (Model, init, view)

import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Route exposing (pushUrl, routeToString)


type alias Model =
    { authenticated : Bool
    , navKey : Nav.Key
    }


type Msg
    = LogoutClick



-- VIEW --


view : Model -> Html Msg
view model =
    -- TODO: css to make it look like not shit
    div []
        ([ a [ href (routeToString Route.Home) ]
            [ button [] [ text "net-go" ] ]
         ]
            ++ viewNavBarButtons model
        )


viewNavBarButtons : Model -> List (Html Msg)
viewNavBarButtons model =
    if model.authenticated then
        [ button [ onClick LogoutClick ] [ text "Logout" ]
        ]

    else
        [ a [ href (routeToString Route.SignUp) ]
            [ button [] [ text "Sign Up" ] ]
        , a [ href (routeToString Route.SignIn) ]
            [ button [] [ text "Sign In" ] ]
        ]



-- UPDATE --


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LogoutClick ->
            -- TODO: clear auth cookie and send logout msg to main.elm (do we need to tell backend?)
            ( { model | authenticated = False }
            , pushUrl Route.Home model.navKey
            )



-- INIT --


init : Nav.Key -> ( Model, Cmd Msg )
init navKey =
    -- TODO: accept authed input
    ( initialModel navKey False
    , Cmd.none
    )


initialModel : Nav.Key -> Bool -> Model
initialModel navKey authed =
    { authenticated = authed
    , navKey = navKey
    }
