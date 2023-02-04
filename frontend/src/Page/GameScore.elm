module Page.GameScore exposing (Model, Msg, init, update, view)

import Html exposing (..)


type alias Model =
    {}


type Msg
    = Todo



-- VIEW


view : Model -> Html Msg
view model =
    text "TODO"



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Todo ->
            ( model
            , Cmd.none
            )



-- INIT


init : Model
init =
    {}
