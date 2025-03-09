module Page.JoinGame exposing (Model, Msg, view, update, init)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Model.Game exposing (Game, getLastMove)
import API.Games exposing (listGamesByUser)
import RemoteData exposing (WebData)
import Route
import View.Loading exposing (viewLoading)
import View.Error exposing (viewErrorBanner)
import Error exposing (stringFromHttpError)

type Msg
    = DataReceived (WebData (List Game))
    | RejectGameClick


type alias Model =
    { remoteData : WebData (List Game)
    , unjoinedGames : Maybe (List Game)
    , errorMessage : Maybe String
    }

-- VIEW --

joinableGameView : Game -> Html Msg
joinableGameView game =
    case game.id of
        Just gameId ->
            div [ class "container border border-gray-600 rounded p-2 drop-shadow" ]
                [ div [ class "flex flex-row justify-center gap-3" ]
                      [ p [ class "font-bold" ] [ text <| game.blackPlayerName ++ " (B)" ]
                      , p [] [ text "vs." ]
                      , p [ class "font-bold" ] [ text <| game.whitePlayerName ++ " (W)" ]
                      ]
                , div [ class "mt-8 flex flex-row justify-center gap-1" ]
                    [ a [ href (Route.routeToString (Route.GamePlay gameId)) ]
                          [ button [ class "btn" ] [ text "Accept" ]
                          ]
                    , button [ class "btn-base bg-red-500 text-white hover:bg-red-700"
                             , onClick RejectGameClick
                             ] [ text "Reject" ]
                    ]
                ]
        Nothing ->
            text "" -- this should never happen


view : Model -> Html Msg
view model =
    let
        viewContent =
            case (model.unjoinedGames, model.errorMessage) of
                (Just games, _) ->
                    div [ class "w-full flex flex-col gap-4 justify-center items-center" ]
                        (List.map (joinableGameView) games)

                (Nothing, Nothing) ->
                    viewLoading "Loading..."

                (Nothing, Just errMsg) ->
                    viewErrorBanner errMsg
    in
    div [ class "w-full flex flex-col p-2 gap-3 justify-center items-center" ]
        [ h2 [ class "text-2xl" ] [ text "Games invites" ]
        , viewContent
        ]

-- UPDATE --

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RejectGameClick ->
            -- TODO: req backend to delete game (should there be conditions for deletion being allowed?)
            (model, Cmd.none)

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
                            Just <| List.filter
                                (\game ->
                                     -- find color of user (match curr user id against game player ids? but not part of elm game...).
                                     -- filter out games where lastMove[PLayerColor] == Nothing
                                     case getLastMove game of
                                         Just _ ->
                                            True
                                         Nothing ->
                                            False
                                )
                                allGames

                        _ ->
                            Nothing
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
