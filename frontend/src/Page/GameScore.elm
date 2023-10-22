module Page.GameScore exposing (Model, Msg, init, update, view)

import Html exposing (..)
import Logic.Scoring exposing (scoreGame)
import Model.Game as Game exposing (Game)
import Model.Score as Score exposing (Score)
import Random


type alias Model =
    { initialSeed : Int
    , game : Game
    , score : Score
    }


type Msg
    = NewRandomSeed Int



-- VIEW


view : Model -> Html Msg
view model =
    text "TODO"



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NewRandomSeed seed ->
            -- TODO: run score game
            ( { model | score = scoreGame model.game seed }
            , Cmd.none
            )



-- INIT


init : Game -> ( Model, Cmd Msg )
init initialGame =
    ( initialModel initialGame
    , Random.generate NewRandomSeed (Random.int 0 42069)
    )


initialModel : Game -> Model
initialModel game =
    { initialSeed = 0
    , game = game
    , score = game.score
    }
