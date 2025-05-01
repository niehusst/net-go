module Page.JoinGame exposing (Model, Msg, init, update, view)

import API.Games exposing (deleteGame, listGamesByUser)
import Error exposing (CustomWebData, newErrorResp, stringFromHttpError)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Model.Game exposing (Game, getLastMove)
import RemoteData
import Route
import View.Error exposing (viewErrorBanner)
import View.Loading exposing (viewLoading)


type Msg
    = DataReceived (CustomWebData (List Game))
    | RejectGameClick String -- clicked game ID
    | GameDeleted String (Result Http.Error ())


type alias Model =
    { remoteData : CustomWebData (List Game)
    , unjoinedGames : Maybe (List Game)
    , errorMessage : Maybe String
    }



-- VIEW --


joinableGameView : Game -> Html Msg
joinableGameView game =
    case game.id of
        Just gameId ->
            div [ class "container border border-gray-300 rounded p-2 shadow" ]
                [ h2 [ class "text-lg" ] [ text <| "ID#" ++ gameId ]
                , div [ class "flex flex-row justify-center gap-3" ]
                    [ p [ class "font-bold" ] [ text <| game.blackPlayerName ++ " (B)" ]
                    , p [] [ text "vs." ]
                    , p [ class "font-bold" ] [ text <| game.whitePlayerName ++ " (W)" ]
                    ]
                , div [ class "mt-8 flex flex-row justify-center gap-1" ]
                    [ a [ href (Route.routeToString (Route.GamePlay gameId)) ]
                        [ button [ class "btn" ] [ text "Accept" ]
                        ]
                    , button
                        [ class "btn-base bg-red-500 text-white hover:bg-red-700"
                        , onClick <| RejectGameClick gameId
                        ]
                        [ text "Reject" ]
                    ]
                ]

        Nothing ->
            text ""


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
            case ( model.remoteData, model.unjoinedGames ) of
                ( RemoteData.Loading, _ ) ->
                    viewLoading "Loading..."

                ( _, Just games ) ->
                    div [ class "w-full flex flex-col gap-4 justify-center items-center" ]
                        (List.map joinableGameView games)

                ( _, _ ) ->
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
        GameDeleted gameId (Result.Ok _) ->
            let
                filteredGames =
                    case model.unjoinedGames of
                        Just games ->
                            Just <|
                                List.filter
                                    (\game ->
                                        case game.id of
                                            Just id ->
                                                id /= gameId

                                            Nothing ->
                                                True
                                    )
                                    games

                        Nothing ->
                            Nothing
            in
            ( { model | unjoinedGames = filteredGames }
            , Cmd.none
            )

        GameDeleted gameId (Result.Err err) ->
            ( { model | errorMessage = Just <| stringFromHttpError <| newErrorResp err Nothing }
            , Cmd.none
            )

        RejectGameClick gameId ->
            ( { model | errorMessage = Nothing }
            , deleteGame gameId (GameDeleted gameId)
            )

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
                            Just <|
                                List.filter
                                    (\game ->
                                        -- filter out games where the player has made a move
                                        -- or where the game is already over.
                                        -- Keep fresh games user has not played in yet.
                                        case getLastMove game game.playerColor of
                                            Just _ ->
                                                False

                                            Nothing ->
                                                not game.isOver
                                    )
                                    allGames

                        _ ->
                            Nothing
            in
            ( { model
                | remoteData = webdata
                , errorMessage = newErrorMessage
                , unjoinedGames = newUnjoinedGames
              }
            , Cmd.none
            )



-- INIT --


init : ( Model, Cmd Msg )
init =
    ( { remoteData = RemoteData.Loading
      , errorMessage = Nothing
      , unjoinedGames = Nothing
      }
    , listGamesByUser DataReceived
    )
