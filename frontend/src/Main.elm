module Main exposing (main)

import Browser exposing (Document, UrlRequest)
import Browser.Navigation as Nav
import Html exposing (Html)
import Model.Board as Board
import Model.ColorChoice as ColorChoice
import Model.Game as Game
import Page
import Page.GameCreate as GameCreate
import Page.GamePlay as GamePlay
import Page.Home as Home
import Page.NotFound as NotFound
import Page.SignIn as SignIn
import Page.SignUp as SignUp
import Route exposing (Route, pushUrl)
import Session exposing (Session)
import Url exposing (Url)


type alias Model =
    { page : Page
    , route : Route
    , session : Session
    , navKey : Nav.Key
    , subpageData : SubpageData
    }

type SubpageData
    = None
    | GameCreateForm GameCreate.FormData

type Page
    = NotFoundPage
    | HomePage Home.Model
    | GameCreatePage GameCreate.Model
    | GamePlayPage GamePlay.Model
    | SignUpPage SignUp.Model
    | SignInPage SignIn.Model


type Msg
    = LinkClicked UrlRequest
    | UrlChanged Url
    | HomePageMsg Home.Msg
    | GameCreatePageMsg GameCreate.Msg
    | GamePlayPageMsg GamePlay.Msg
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

        SignUpPage _ ->
            "Sign Up"

        SignInPage _ ->
            "Sign In"



-- UPDATE --


{-| Msg interception for any page messages before
passing them along to intended Page, allowing us to save, or update
shared data accordingly.
This allows us to share specific data, or pass data between pages.
-}
interceptMsg : Msg -> Model -> Model
interceptMsg msg model =
    case msg of
        SignUpPageMsg (SignUp.UpdateSession session) ->
            { model | session = session }

        SignInPageMsg (SignIn.UpdateSession session) ->
            { model | session = session }

        GameCreatePageMsg (GameCreate.SendFormDataToMain data) ->
            { model | subpageData = GameCreateForm data  }

        _ ->
            -- we dont need to intercept this message; no-op
            model


update : Msg -> Model -> ( Model, Cmd Msg )
update msg rawModel =
    let
        -- only update the model; msg must be passed down to child
        model =
            interceptMsg msg rawModel
    in
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

        ( SignUpPageMsg submsg, SignUpPage pageModel ) ->
            let
                ( updatedPageModel, updatedCmd ) =
                    SignUp.update submsg pageModel
            in
            ( { model | page = SignUpPage updatedPageModel }
            , Cmd.map SignUpPageMsg updatedCmd
            )

        ( SignInPageMsg submsg, SignInPage pageModel ) ->
            let
                ( updatedPageModel, updatedCmd ) =
                    SignIn.update submsg pageModel
            in
            ( { model | page = SignInPage updatedPageModel }
            , Cmd.map SignInPageMsg updatedCmd
            )

        ( _, _ ) ->
            -- generic mismatch case handler
            ( model, Cmd.none )



-- INIT --


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url navKey =
    -- TODO: create real session value from cookie existence
    let
        model =
            { page = NotFoundPage
            , route = Route.parseUrl url
            , session = Session.init navKey
            , navKey = navKey
            , subpageData = None
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
                            GameCreate.init model.navKey
                    in
                    ( GameCreatePage pageModel
                    , Cmd.map GameCreatePageMsg pageCmds
                    )

                Route.GamePlay ->
                    case model.subpageData of
                        GameCreateForm formData ->
                            let
                                ( pageModel, pageCmds ) =
                                    GamePlay.init formData.boardSize formData.colorChoice formData.komi
                            in
                                ( GamePlayPage pageModel
                                , Cmd.map GamePlayPageMsg pageCmds
                                )

                        _ ->
                            -- someone probably navigated directly to this route w/o submitting form; send home
                            ( NotFoundPage
                            , Route.pushUrl Route.Home model.navKey
                            )

                Route.SignUp ->
                    let
                        ( pageModel, pageCmds ) =
                            SignUp.init model.session
                    in
                    ( SignUpPage pageModel
                    , Cmd.map SignUpPageMsg pageCmds
                    )

                Route.SignIn ->
                    let
                        ( pageModel, pageCmds ) =
                            SignIn.init model.session
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
