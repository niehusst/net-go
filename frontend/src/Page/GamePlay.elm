module Page.GamePlay exposing (Model, Msg, init, isInnerCell, update, view)

import API.Games exposing (getGame)
import Array
import Browser.Navigation as Nav
import Error exposing (stringFromHttpError)
import Html exposing (..)
import Html.Attributes exposing (class, href, src, style)
import Html.Events exposing (onClick)
import Logic.Rules exposing (..)
import Logic.Scoring exposing (scoreGame)
import Model.Board as Board exposing (..)
import Model.ColorChoice as ColorChoice exposing (..)
import Model.Game as Game exposing (..)
import Model.Move as Move exposing (..)
import Model.Piece as Piece exposing (..)
import Model.Score as Score
import Random
import RemoteData exposing (WebData)
import Route exposing (routeToString)
import Svg exposing (circle, svg)
import Svg.Attributes as SAtts


type Msg
    = PlayPiece Int
    | PlayPass
    | Resign
    | CalculateGameScore Int
    | FetchGame String -- gameId
    | DataReceived (WebData Game)


type PlayState
    = Playing
    | CalculatingScore
    | FinalScore Score.Score


type alias Model =
    { remoteGameData : WebData Game

    -- for showing client side changes immediately while they are
    -- being propogated to backend
    , clientGameData : Maybe Game
    , activeTurn : Bool
    , invalidMoveAlert : Maybe String
    , initialSeed : Int
    , playState : PlayState
    }


gameFromModel : Model -> Maybe Game
gameFromModel model =
    case ( model.clientGameData, model.remoteGameData ) of
        ( Just game, _ ) ->
            Just game

        ( Nothing, RemoteData.Success game ) ->
            Just game

        _ ->
            Nothing


startScoring : Model -> Maybe ColorChoice -> ( Model, Cmd Msg )
startScoring model forfeitColor =
    case ( gameFromModel model, forfeitColor ) of
        ( Just game, Just color ) ->
            -- skip calculation; someone forfeit
            let
                forfeitScore =
                    Score.setForfeitColor color game.score

                completedGame =
                    setScore forfeitScore game
                        |> setIsOver True
            in
            ( { model
                | playState = FinalScore forfeitScore
                , clientGameData = Just completedGame
              }
            , Cmd.none
              -- TODO: send game scored game to backend!
            )

        _ ->
            -- trigger score calculation
            ( { model
                | playState = CalculatingScore
              }
            , Random.generate CalculateGameScore (Random.int 0 42069)
            )



-- VIEW --


view : Model -> Html Msg
view model =
    -- show a game if we have one; local or remote
    case gameFromModel model of
        Just game ->
            case model.playState of
                Playing ->
                    gamePlayView game model.invalidMoveAlert model.activeTurn

                CalculatingScore ->
                    -- TODO: this view is never showing... browser too busy?
                    loadingView

                FinalScore score ->
                    scoreView score game.playerColor

        Nothing ->
            case model.remoteGameData of
                RemoteData.Loading ->
                    loadingView

                RemoteData.Failure error ->
                    -- TODO: imporove
                    text ("Error fetching game: " ++ stringFromHttpError error)

                _ ->
                    -- RemoteData.NotAsked + RemoteData.Success
                    -- niether of which should ever happen/reach here
                    -- TODO: this will never happen? share case result w/ err
                    text "Error"


loadingView : Html Msg
loadingView =
    div [ class "flex flex-col items-center justify-center" ]
        [ p [] [ text "Calculating final score..." ]
        , img [ src "/static/resources/loading-wheel.svg" ] []
        ]


scoreView : Score.Score -> ColorChoice -> Html Msg
scoreView score playerColor =
    let
        resultSummaryText =
            case Score.winningColor score of
                Just victor ->
                    if victor == playerColor then
                        "You Won!"

                    else
                        "You Lost."

                Nothing ->
                    ""
    in
    div [ class "flex flex-col gap-5 py-5 items-center justify-center" ]
        [ h3 [ class "text-5xl" ] [ text "Final Score:" ]
        , h1 [ class "text-9xl" ] [ text <| Score.scoreToString score ]
        , p [ class "text-base" ] [ text ("Komi was: " ++ String.fromFloat score.komi) ]
        , h2 [ class "text-7xl" ] [ text resultSummaryText ]
        , button [ class "btn" ]
            [ a [ href (routeToString Route.Home) ] [ text "Return Home" ]
            ]
        ]


gamePlayView : Game -> Maybe String -> Bool -> Html Msg
gamePlayView game invalidMoveAlert activeTurn =
    div [ class "p-5 flex flex-col gap-4" ]
        [ viewWaitForOpponent activeTurn
        , viewBuildBoard game
        , viewAlert invalidMoveAlert
        , div [ class "flex gap-4" ]
            [ button
                [ class "btn"
                , onClick PlayPass
                ]
                [ text "Pass" ]
            , button
                [ class "btn-base bg-red-500 text-white border-solid border-2 border-red-500 hover:bg-white hover:text-red-500"
                , onClick Resign
                ]
                [ text "Resign" ]
            ]
        ]


viewAlert : Maybe String -> Html Msg
viewAlert error =
    case error of
        Nothing ->
            text ""

        Just errorMessage ->
            div
                [ class "bg-red-300 rounded p-2" ]
                [ p [ class "font-bold" ]
                    [ text ("Invalid move: " ++ errorMessage) ]
                ]


viewWaitForOpponent : Bool -> Html Msg
viewWaitForOpponent activeTurn =
    if activeTurn then
        text "It's your turn!"

    else
        text "Wait for opponent to play..."


viewBuildBoard : Game -> Html Msg
viewBuildBoard game =
    let
        intSize =
            boardSizeToInt game.boardSize

        gridStyle =
            String.join " " (List.repeat intSize "auto")
    in
    div [ class "board", style "grid-template-columns" gridStyle ]
        (viewGameBoard game)


viewGameBoard : Game -> List (Html Msg)
viewGameBoard game =
    let
        lastMovePosition =
            case game.history of
                [] ->
                    -1

                move :: _ ->
                    case move of
                        Move.Play _ pos ->
                            pos

                        _ ->
                            -1
    in
    Array.toList
        (Array.indexedMap
            (viewBuildCell game.boardSize game.playerColor lastMovePosition)
            game.board
        )


{-| determines if cell position `index` is not going
to be on the outer right or bottom edges of the game
board (when rendered in 2D grid instead of flat array).
-}
isInnerCell : BoardSize -> Int -> Bool
isInnerCell boardSize index =
    let
        intSize =
            boardSizeToInt boardSize

        isLastRow =
            index >= intSize * (intSize - 1)

        isLastCol =
            remainderBy intSize (index + 1) == 0
    in
    not (isLastRow || isLastCol)


viewBuildCell : BoardSize -> ColorChoice -> Int -> Int -> Piece -> Html Msg
viewBuildCell boardSize color lastMoveIndex index piece =
    let
        isLastMoveIndex =
            index == lastMoveIndex

        pieceHtml =
            renderPiece piece isLastMoveIndex

        hoverClass =
            "hidden-hover-element board-square-" ++ colorToString color

        cellClass =
            if isInnerCell boardSize index then
                "board-square inner-board-square"

            else
                "board-square"
    in
    div [ class cellClass, onClick (PlayPiece index) ]
        [ pieceHtml
        , div [ class hoverClass ] []
        ]


renderPiece : Piece -> Bool -> Html msg
renderPiece piece isLastMove =
    let
        fillColor =
            case piece of
                BlackStone ->
                    "black"

                WhiteStone ->
                    "white"

                None ->
                    ""

        pieceSvgList =
            let
                filledPiece =
                    [ circle
                        [ SAtts.cx "13"
                        , SAtts.cy "13"
                        , SAtts.r "11"
                        , SAtts.fill fillColor
                        ]
                        []
                    ]
            in
            if isLastMove then
                filledPiece
                    ++ [ circle
                            [ SAtts.cx "13"
                            , SAtts.cy "13"
                            , SAtts.r "5"
                            , SAtts.fill "#f5c71a"
                            ]
                            []
                       ]

            else
                filledPiece
    in
    if piece == None then
        text ""

    else
        svg
            [ SAtts.width "26"
            , SAtts.height "26"
            , SAtts.viewBox "0 0 26 26"
            , SAtts.style "position: absolute;"
            ]
            pieceSvgList



-- UPDATE --


handlePlayPiece : Model -> Int -> ( Model, Cmd Msg )
handlePlayPiece model index =
    case gameFromModel model of
        Nothing ->
            -- game required to be loaded to handle this msg
            ( model
            , Cmd.none
            )

        Just game ->
            let
                move =
                    Move.Play (colorToPiece game.playerColor) index

                ( moveIsValid, errorMessage ) =
                    validMove move game
            in
            if moveIsValid then
                let
                    updatedModel =
                        { model
                            | clientGameData =
                                playMove move game
                                    -- TODO: remove color swap w/ networking
                                    |> setPlayerColor (colorInverse game.playerColor)
                                    |> Just
                            , activeTurn = not model.activeTurn
                            , invalidMoveAlert = Nothing
                        }
                in
                ( updatedModel
                , endTurn updatedModel
                )

            else
                ( { model | invalidMoveAlert = errorMessage }
                , Cmd.none
                )


handlePlayPass : Model -> ( Model, Cmd Msg )
handlePlayPass model =
    case gameFromModel model of
        Just game ->
            let
                updatedGame =
                    playMove (Move.Pass (colorToPiece game.playerColor)) game
                        |> setIsOver (isGameEnded game)
                        -- TODO remove color swap w/ networking
                        |> setPlayerColor (colorInverse game.playerColor)

                ( updatedModel, command ) =
                    -- check if game ended by Pass moves
                    if updatedGame.isOver then
                        startScoring model Nothing

                    else
                        let
                            modelWithMove =
                                { model
                                    | activeTurn = not model.activeTurn
                                    , invalidMoveAlert = Nothing
                                    , clientGameData = Just updatedGame
                                }
                        in
                        ( modelWithMove
                        , endTurn modelWithMove
                        )
            in
            ( updatedModel
            , command
            )

        Nothing ->
            -- game required to be loaded to handle this msg
            ( model
            , Cmd.none
            )


handleCalculateGameScore : Model -> Int -> ( Model, Cmd Msg )
handleCalculateGameScore model seed =
    case gameFromModel model of
        Nothing ->
            -- game required to be loaded to handle this msg
            ( model
            , Cmd.none
            )

        Just game ->
            let
                finalScore =
                    scoreGame game seed

                completedGame =
                    setScore finalScore game
                        |> setIsOver True
            in
            ( { model
                | playState = FinalScore finalScore
                , clientGameData = Just completedGame
              }
            , Cmd.none
              -- TODO: send game scored game to backend!
            )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PlayPiece index ->
            handlePlayPiece model index

        PlayPass ->
            handlePlayPass model

        Resign ->
            let
                resignedColor =
                    case gameFromModel model of
                        Nothing ->
                            -- should never happen, but fallthrough to score calc (which falls back to doing nothing)
                            Nothing

                        Just game ->
                            Just game.playerColor
            in
            startScoring model resignedColor

        CalculateGameScore seed ->
            handleCalculateGameScore model seed

        FetchGame gameId ->
            ( model
            , getGame gameId DataReceived
            )

        DataReceived responseGame ->
            let
                activeTurn =
                    case responseGame of
                        RemoteData.Success game ->
                            Game.isActiveTurn game

                        _ ->
                            False

                clientGameData =
                    case responseGame of
                        RemoteData.Success game ->
                            Just game

                        _ ->
                            Nothing
            in
            ( { model
                | remoteGameData = responseGame
                , clientGameData = clientGameData
                , activeTurn = activeTurn
              }
            , Cmd.none
            )


endTurn : Model -> Cmd Msg
endTurn model =
    -- TODO: placeholder turn swap w/o networking
    -- TODO: send updated clientGameData to server to persist
    Cmd.none



-- INIT --


init : String -> ( Model, Cmd Msg )
init gameId =
    ( initialModel
    , getGame gameId DataReceived
    )


initialModel : Model
initialModel =
    { remoteGameData = RemoteData.Loading
    , clientGameData = Nothing
    , activeTurn = False -- TODO colorChoice == Black
    , invalidMoveAlert = Nothing
    , playState = Playing
    , initialSeed = 0
    }
