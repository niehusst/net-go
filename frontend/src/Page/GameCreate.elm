module Page.GameCreate exposing (Model, Msg, init, update, view)

import Html exposing (..)
import Html.Attributes exposing (href)
import Model.Board exposing (BoardSize(..), boardSizeToInt)
import Model.Piece exposing (ColorChoice(..), colorToString)
import Route exposing (Route, routeToString)


type alias Model =
    { boardSize : BoardSize
    , colorChoice : ColorChoice
    , komi : Float
    }


type Msg
    = PlaceHolder



-- VIEW --


view : Model -> Html msg
view model =
    div []
        [ h2 [] [ text "Game Settings" ]
        , viewGameSettings model
        , a [ href (routeToString Route.GamePlay) ]
            [ button [] [ text "Create game" ] ]
        ]


viewGameSettings : Model -> Html msg
viewGameSettings model =
    -- TODO make this a form
    div []
        [ text ("Color: " ++ colorToString model.colorChoice)
        , br [] []
        , text ("Board size: " ++ String.fromInt (boardSizeToInt model.boardSize))
        , br [] []
        , text ("Komi: " ++ String.fromFloat model.komi)
        , br [] []
        ]



-- UPDATE --


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model
    , Cmd.none
    )



-- INIT --


init : ( Model, Cmd Msg )
init =
    ( initialModel
    , Cmd.none
    )


initialModel : Model
initialModel =
    { boardSize = Full
    , colorChoice = Black
    , komi = 5.5 -- current Japanese regulation komi
    }
