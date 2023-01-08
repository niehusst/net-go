module Page.Home exposing (Model, Msg, init, update, view)

import Html exposing (..)
import Html.Attributes exposing (..)


type Msg
    = Placeholder


type alias Model =
    {}



-- VIEW --


view : Model -> Html Msg
view model =
    div [ class "jumbotron" ]
        [ h1 [] [ text "Play Go online with a friend!" ]
        , p []
            [ text "It's pretty "
            , strong [] [ text "FUN." ]
            , text <|
                """ 
                More functionality coming soon.
                """
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
