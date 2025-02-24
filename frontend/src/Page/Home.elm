module Page.Home exposing (Model, Msg, init, update, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Route exposing (Route, routeToString)


type Msg
    = Placeholder


type alias Model =
    {}



-- VIEW --


view : Model -> Html Msg
view model =
    -- TODO: dont list buttons if logged out? since all require auth??? have diff unauthed UI for home?
    div [ class "flex items-center justify-center h-full" ]
        [ div [ class "flex flex-col h-full gap-4 items-center justify-center text-center" ]
            [ h1
                [ class "text-3xl font-bold" ]
                [ text "Play Go online with friends!" ]
            , a
                [ href (routeToString Route.GameCreate)
                , class "my-1"
                ]
                [ button [ class "btn" ] [ text "Create a game" ] ]
            , a
                [ href (routeToString Route.JoinGame)
                , class "my-1"
                ]
                [ button [ class "btn" ] [ text "Join a game" ] ]
            , a
                [ href (routeToString Route.ContinueGame)
                , class "my-1"
                ]
                [ button [ class "btn" ] [ text "Continue a game" ] ]
            ]
        ]



-- UPDATE --


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Placeholder ->
            ( model, Cmd.none )



-- INIT --


init : ( Model, Cmd Msg )
init =
    ( {}
    , Cmd.none
    )
