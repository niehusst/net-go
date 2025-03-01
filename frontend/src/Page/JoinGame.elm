module Page.JoinGame exposing (Model, Msg, view, update, init)

import Html exposing (..)
import Html.Attributes exposing (..)
import Model.Game exposing (Game)
import API.Games exposing (listGamesByUser)
import RemoteData exposing (WebData)
import View.Loading exposing (viewLoading)
import View.Error exposing (viewErrorBanner)

type Msg
    = DataReceived (WebData (List Game))


type alias Model =
    { remoteData : WebData (List Game)
    , unjoinedGames : Maybe (List Game)
    , errorMessage : Maybe String
    }

-- VIEW --

joinableGameView : Game -> Html Msg
joinableGameView game =
    div [] [text "game"]


view : Model -> Html Msg
view model =
    case model.unjoinedGames of
        Just games ->
            joinableGameView games
        Nothing ->
            viewLoading "Loading..."

    case model.errorMessage of
        Just errMsg ->
            viewErrorBanner errMsg
        Nothing ->
            text ""

    div []
        []

-- UPDATE --

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DataReceived webdata ->
            let
                newErrorMessage =
                    case webdata of
                        RemoteData.Failure error ->
                            Just (stringFromHttpError error)

                        _ ->
                            Nothing

                newUnjoinedGames =
                    case webdata of
                        RemoteData.Success allGames ->
                            List.filter
                                (\game ->
                                     -- find color of user (match curr user id against game player ids? but not part of elm game...).
                                     -- filter out games where lastMove[PLayerColor] == Nothing
                                )
                                allGames
            in
            ({ model
             | errorMessage = newErrorMessage
             , unjoinedGames = newUnjoinedGames
             }
            , Cmd.none)

-- INIT --

init : (Model, Cmd Msg)
init =
    ( { remoteData = RemoteData.Loading
    , errorMessage = Nothing
    , unjoinedGames = Nothing
    }
    , listGamesByUser DataReceived
    )
