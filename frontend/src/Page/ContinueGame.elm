module Page.ContinueGame exposing (Model, Msg, view, update, init)

import Html exposing (..)
import Html.Attributes exposing (..)
import Model.Game exposing (Game)
import API.Games exposing (listGamesByUser)
import RemoteData exposing (WebData)

type Msg
    = DataReceived (WebData (List Game))


type alias Model =
    { remoteData : WebData (List Game)
    }

-- VIEW --

view : Model -> Html Msg
view model =
    div [] [text "cont page"]

-- UPDATE --

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DataReceived webdata ->
            (model, Cmd.none)

-- INIT --

init : (Model, Cmd Msg)
init =
    ( { remoteData = RemoteData.Loading
    }
    , listGamesByUser DataReceived
    )
