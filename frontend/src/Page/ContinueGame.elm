module Page.ContinueGame exposing (Model, Msg, view, update, init)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Model.Game exposing (Game, getLastMove, isActiveTurn)
import API.Games exposing (listGamesByUser, deleteGame)
import RemoteData exposing (WebData)
import Route
import View.Loading exposing (viewLoading)
import View.Error exposing (viewErrorBanner)
import Error exposing (stringFromHttpError)

type Msg
    = DataReceived (WebData (List Game))


type alias Model =
    { remoteData : WebData (List Game)
    , ongoingGames : Maybe (List Game)
    , errorMessage : Maybe String
    }

-- VIEW --

ongoingGameView : Game -> Html Msg
ongoingGameView game =
    let
        nextTurnAlert =
            if isActiveTurn game then
                p [ class "my-3 text-center text-lg text-accent1 font-bold underline" ]
                  [ text "It's your turn!" ]
            else
                text ""
    in
    case game.id of
        Just gameId ->
            a [ class "container border border-gray-300 rounded p-2 shadow"
              , href (Route.routeToString (Route.GamePlay gameId))
              ]
              [ h2 [ class "text-large" ] [ text <| "ID#" ++ gameId ]
              , div [ class "flex flex-row justify-center gap-3" ]
                    [ p [ class "font-bold" ] [ text <| game.blackPlayerName ++ " (B)" ]
                    , p [] [ text "vs." ]
                    , p [ class "font-bold" ] [ text <| game.whitePlayerName ++ " (W)" ]
                    ]
              , nextTurnAlert
              ]
        Nothing ->
            text "" -- this should never happen

view : Model -> Html Msg
view model =
    let
        viewError =
            case model.errorMessage of
                Just errMsg ->
                    viewErrorBanner errMsg

                Nothing ->
                    text ""
        viewContent =
            case ( model.remoteData, model.ongoingGames ) of
                (RemoteData.Loading, _) ->
                    viewLoading "Loading..."

                (_, Just games) ->
                    div [ class "w-full flex flex-col gap-4 justify-center items-center" ]
                        (List.map (ongoingGameView) games)

                (_, _) ->
                    text ""
    in
    div [ class "w-full flex flex-col p-2 gap-3 justify-center items-center" ]
        [ h2 [ class "text-2xl" ] [ text "Games invites" ]
        , viewError
        , viewContent
        ]

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

                newOngoingGames =
                    case webdata of
                        RemoteData.Success allGames ->
                            Just <| List.filter
                                (\game ->
                                     -- filter out games where the player hasnt made a move
                                     -- or where the game is already over.
                                     case getLastMove game of
                                         Just _ ->
                                            not game.isOver

                                         Nothing ->
                                            False
                                )
                                allGames

                        _ ->
                            Nothing
            in
            ({ model
             | remoteData = webdata
             , errorMessage = newErrorMessage
             , ongoingGames = newOngoingGames
             }
            , Cmd.none)

-- INIT --

init : (Model, Cmd Msg)
init =
    ( { remoteData = RemoteData.Loading
      , ongoingGames = Nothing
      , errorMessage = Nothing
      }
    , listGamesByUser DataReceived
    )
