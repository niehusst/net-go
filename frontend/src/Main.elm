module Main exposing (main)

import Browser exposing (Document, UrlRequest)
import Browser.Navigation as Nav
import Html exposing (..)
import Model.Board as Board exposing (BoardSize)
import Model.Piece as Piece exposing (ColorChoice)
import Page
import Page.GameCreate as GameCreate
import Page.GamePlay as GamePlay
import Page.GameScore as GameScore
import Page.Home as Home
import Page.NotFound as NotFound
import Page.SignIn as SignIn
import Page.SignUp as SignUp
import Route exposing (Route)
import Session exposing (Session)
import Url exposing (Url)


type alias Model =
    { page : Page
    , route : Route
    , session : Session
    }


type Page
    = NotFoundPage
    | HomePage Home.Model
    | GameCreatePage GameCreate.Model
    | GamePlayPage GamePlay.Model
    | GameScorePage GameScore.Model
    | SignUpPage SignUp.Model
    | SignInPage SignIn.Model


type Msg
    = LinkClicked UrlRequest
    | UrlChanged Url
    | HomePageMsg Home.Msg
    | GameCreatePageMsg GameCreate.Msg
    | GamePlayPageMsg GamePlay.Msg
    | GameScorePageMsg GameScore.Msg
    | SignUpPageMsg SignUp.Msg
    | SignInPageMsg SignIn.Msg



-- VIEW --


{-| Wrap the current page with header + footer content
-}
view : Model -> Document Msg
view model =
    { title = viewTabTitle model.page
    , body = Page.viewHeader model.session :: viewCurrentPage model :: [ Page.viewFooter ]
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
                |> Html.map GameCreatePageMsg

        GamePlayPage pageModel ->
            GamePlay.view pageModel
                |> Html.map GamePlayPageMsg

        GameScorePage pageModel ->
            GameScore.view pageModel
                |> Html.map GameScorePageMsg

        SignUpPage pageModel ->
            SignUp.view pageModel
                |> Html.map SignUpPageMsg

        SignInPage pageModel ->
            SignIn.view pageModel
                |> Html.map SignInPageMsg


viewTabTitle : Page -> String
viewTabTitle page =
    case page of
        NotFoundPage ->
            "Not found"

        HomePage _ ->
            "Home"

        GameCreatePage _ ->
            "Create Game"

        GamePlayPage _ ->
            "Game"

        GameScorePage _ ->
            "Score"

        SignUpPage _ ->
            "Sign Up"

        SignInPage _ ->
            "Sign In"



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
                    , Nav.pushUrl (Session.navKey model.session) (Url.toString url)
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

        ( GameCreatePageMsg submsg, GameCreatePage pageModel ) ->
            let
                ( updatedPageModel, updatedCmd ) =
                    GameCreate.update submsg pageModel
            in
            ( { model | page = GameCreatePage updatedPageModel }
            , Cmd.map GameCreatePageMsg updatedCmd
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

        ( SignUpPageMsg submsg, SignUpPage pageModel ) ->
            let
                ( updatedPageModel, updatedCmd ) =
                    SignUp.update submsg pageModel
            in
            ( { model | page = SignUpPage updatedPageModel }
            , Cmd.map SignUpPageMsg updatedCmd
            )

        ( _, _ ) ->
            -- generic mismatch case handler
            ( model, Cmd.none )



-- INIT --


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url navKey =
    -- TODO: create real session value, not default unauthed
    let
        model =
            { page = NotFoundPage
            , route = Route.parseUrl url
            , session = Session.init navKey
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
                        ( pageModel, pageCmds ) =
                            GameCreate.init
                    in
                    ( GameCreatePage pageModel
                    , Cmd.map GameCreatePageMsg pageCmds
                    )

                Route.GamePlay ->
                    let
                        -- TODO: give real values from form
                        ( pageModel, pageCmds ) =
                            GamePlay.init Board.Small Piece.Black (Session.navKey model.session)
                    in
                    ( GamePlayPage pageModel
                    , Cmd.map GamePlayPageMsg pageCmds
                    )

                Route.GameScore ->
                    let
                        ( pageModel, pageCmds ) =
                            GameScore.init
                    in
                    ( GameScorePage pageModel
                    , Cmd.map GameScorePageMsg pageCmds
                    )

                Route.SignUp ->
                    let
                        ( pageModel, pageCmds ) =
                            SignUp.init
                    in
                    ( SignUpPage pageModel
                    , Cmd.map SignUpPageMsg pageCmds
                    )

                Route.SignIn ->
                    let
                        ( pageModel, pageCmds ) =
                            SignIn.init
                    in
                    ( SignInPage pageModel
                    , Cmd.map SignInPageMsg pageCmds
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
