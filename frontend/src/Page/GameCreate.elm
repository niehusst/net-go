module Page.GameCreate exposing (Model, init, view)

import Html exposing (..)
import Html.Attributes exposing (href)
import Model.Board exposing (BoardSize(..), boardSizeToInt)
import Model.ColorChoice exposing (ColorChoice(..), colorToString)
import Route exposing (Route, routeToString)


type alias Model =
    { boardSize : BoardSize
    , colorChoice : ColorChoice
    , komi : Float
    }



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
-- INIT --


init : Model
init =
    initialModel


initialModel : Model
initialModel =
    { boardSize = Full
    , colorChoice = Black
    , komi = 5.5 -- current Japanese regulation komi
    }
