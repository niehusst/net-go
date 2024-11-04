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
    div [ class "flex flex-col w-screen content-center justify-center text-center" ]
        [ h1
            [ class "text-3xl font-bold" ]
            [ text "Play Go online with a friend!" ]
        , p []
            [ text "It's pretty "
            , strong [] [ text "FUN." ]
            , text <|
                """ 
                More functionality coming soon.
                """
            ]
        , a
            [ href (routeToString Route.GameCreate)
            , class "my-1"
            ]
            [ button [ class "btn" ] [ text "Create a game" ] ]
        , a
            [ href "#"
            , class "my-1"
            ]
            [ button [ class "btn" ] [ text "Join a game" ] ]
        , a
            [ href "#"
            , class "my-1"
            ]
            [ button [ class "btn" ] [ text "Continue a game" ] ]
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
