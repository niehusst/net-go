module Main exposing (main)

import Browser exposing (Document, UrlRequest)
import Browser.Navigation as Nav
import Html exposing (..)
import Model.Board as Board exposing (BoardSize)
import Model.Piece as Piece exposing (ColorChoice)
import Page.GameCreate as GameCreate
import Page.GamePlay as GamePlay
import Page.GameScore as GameScore
import Page.Home as Home
import Page.NotFound as NotFound
import Route exposing (Route)
import Url exposing (Url)


type alias Model =
    { page : Page
    , route : Route
    , navKey : Nav.Key
    }


type Page
    = NotFoundPage
    | HomePage Home.Model
    | GameCreatePage GameCreate.Model
    | GamePlayPage GamePlay.Model
    | GameScorePage GameScore.Model


type Msg
    = LinkClicked UrlRequest
    | UrlChanged Url
    | HomePageMsg Home.Msg
    | GamePlayPageMsg GamePlay.Msg
    | GameScorePageMsg GameScore.Msg



-- VIEW --


view : Model -> Document Msg
view model =
    { title = "net-go"
    , body = [ viewCurrentPage model ]
    }


viewCurrentPage : Model -> Html Msg
viewCurrentPage model =
    case model.page of
        NotFoundPage ->
            NotFound.view

        HomePage pageModel ->
            Home.view pageModel
                |> Html.map HomePageMsg

        GameCreatePage pageModel ->
            GameCreate.view pageModel

        GamePlayPage pageModel ->
            GamePlay.view pageModel
                |> Html.map GamePlayPageMsg

        GameScorePage pageModel ->
            GameScore.view pageModel
                |> Html.map GameScorePageMsg



-- UPDATE --


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.page ) of
        ( UrlChanged url, _ ) ->
            let
                newRoute =
                    Route.parseUrl url
            in
            ( { model | route = newRoute }, Cmd.none )
                |> initCurrentPage

        ( LinkClicked urlRequest, _ ) ->
            case urlRequest of
                Browser.Internal url ->
                    ( model
                    , Nav.pushUrl model.navKey (Url.toString url)
                    )

                Browser.External url ->
                    ( model
                    , Nav.load url
                    )

        ( HomePageMsg submsg, HomePage pageModel ) ->
            let
                ( updatedPageModel, updatedCmd ) =
                    Home.update submsg pageModel
            in
            ( { model | page = HomePage updatedPageModel }
            , Cmd.map HomePageMsg updatedCmd
            )

        ( GamePlayPageMsg submsg, GamePlayPage pageModel ) ->
            let
                ( updatedPageModel, updatedCmd ) =
                    GamePlay.update submsg pageModel
            in
            ( { model | page = GamePlayPage updatedPageModel }
            , Cmd.map GamePlayPageMsg updatedCmd
            )

        ( GameScorePageMsg submsg, GameScorePage pageModel ) ->
            let
                ( updatedPageModel, updatedCmd ) =
                    GameScore.update submsg pageModel
            in
            ( { model | page = GameScorePage updatedPageModel }
            , Cmd.map GameScorePageMsg updatedCmd
            )

        ( _, _ ) ->
            -- generic mismatch case handler
            ( model, Cmd.none )



-- INIT --


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url navKey =
    let
        model =
            { page = NotFoundPage
            , route = Route.parseUrl url
            , navKey = navKey
            }
    in
    initCurrentPage ( model, Cmd.none )


initCurrentPage : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
initCurrentPage ( model, existingCmds ) =
    let
        ( currentPage, mappedCmds ) =
            case model.route of
                Route.NotFound ->
                    ( NotFoundPage, Cmd.none )

                Route.Home ->
                    let
                        ( pageModel, pageCmds ) =
                            Home.init
                    in
                    ( HomePage pageModel
                    , Cmd.map HomePageMsg pageCmds
                    )

                Route.GameCreate ->
                    let
                        pageModel =
                            GameCreate.init
                    in
                    ( GameCreatePage pageModel
                    , Cmd.none
                    )

                Route.GamePlay ->
                    let
                        -- TODO: give real values from form
                        pageModel =
                            GamePlay.init Board.Small Piece.Black model.navKey
                    in
                    ( GamePlayPage pageModel
                    , Cmd.none
                    )

                Route.GameScore ->
                    let
                        pageModel =
                            GameScore.init
                    in
                    ( GameScorePage pageModel
                    , Cmd.none
                    )
    in
    ( { model | page = currentPage }
    , Cmd.batch [ existingCmds, mappedCmds ]
    )


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        , onUrlRequest = LinkClicked
        , onUrlChange = UrlChanged
        }
