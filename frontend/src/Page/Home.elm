module Page.Home exposing (Model, Msg, init, update, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Route exposing (Route, routeToString)
import Session exposing (Session(..))


type Msg
    = Placeholder


type alias Model =
    { session : Session }



-- VIEW --


view : Model -> Html Msg
view model =
    let
        pageContent =
            case model.session of
                LoggedIn _ _ ->
                    [ a
                        [ href (routeToString Route.GameCreate) ]
                        [ button [ class "btn" ] [ text "Create a game" ] ]
                    , a
                        [ href (routeToString Route.JoinGame) ]
                        [ button [ class "btn" ] [ text "Join a game" ] ]
                    , a
                        [ href (routeToString Route.ContinueGame) ]
                        [ button [ class "btn" ] [ text "Continue a game" ] ]
                    ]
                LoggedOut _ ->
                    [ p [] [ text "Log into your account to play!"]
                    , div [ class "flex justify-center gap-3"]
                        [ a
                            [ href (routeToString Route.SignIn) ]
                            [ button [class "btn"] [text "Sign in"] ]
                        , a
                            [ href (routeToString Route.SignUp) ]
                            [ button [class "btn"] [text "Sign up"] ]
                        ]
                    ]

    in
    div [ class "flex items-center justify-center h-full" ]
        [ div [ class "flex flex-col h-full gap-4 items-center justify-center text-center" ]
            ((h1
                [ class "text-3xl font-bold mb-5" ]
                [ text "Play Go online with friends!" ])
             :: pageContent)
        ]



-- UPDATE --


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Placeholder ->
            ( model, Cmd.none )



-- INIT --


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session }
    , Cmd.none
    )
