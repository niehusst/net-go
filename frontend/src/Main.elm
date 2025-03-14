module Main exposing (main)

import API.Accounts exposing (doLogout)
import Browser exposing (Document, UrlRequest)
import Browser.Navigation as Nav
import Html exposing (Html, div)
import Html.Attributes exposing (class)
import Http
import Model.Board as Board
import Model.ColorChoice as ColorChoice
import Model.Game as Game
import Page
import Page.ContinueGame as ContinueGame
import Page.GameCreate as GameCreate
import Page.GamePlay as GamePlay
import Page.Home as Home
import Page.JoinGame as JoinGame
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
    }


type Page
    = NotFoundPage
    | HomePage Home.Model
    | GameCreatePage GameCreate.Model
    | GamePlayPage GamePlay.Model
    | SignUpPage SignUp.Model
    | SignInPage SignIn.Model
    | JoinGamePage JoinGame.Model
    | ContinueGamePage ContinueGame.Model


type Msg
    = LinkClicked UrlRequest
    | UrlChanged Url
    | LogoutResponse (Result Http.Error ())
    | HomePageMsg Home.Msg
    | GameCreatePageMsg GameCreate.Msg
    | GamePlayPageMsg GamePlay.Msg
    | SignUpPageMsg SignUp.Msg
    | SignInPageMsg SignIn.Msg
    | JoinGamePageMsg JoinGame.Msg
    | ContinueGamePageMsg ContinueGame.Msg



-- VIEW --


{-| Wrap the current page with header + footer content
-}
viewPageContainer : Model -> Html Msg
viewPageContainer model =
    div [ class "flex flex-col h-screen" ]
        [ Page.viewHeader model.session
        , div [ class "flex-grow" ] [ viewCurrentPage model ]
        , Page.viewFooter
        ]


view : Model -> Document Msg
view model =
    { title = viewTabTitle model.page
    , body = [ viewPageContainer model ]
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

        JoinGamePage pageModel ->
            JoinGame.view pageModel
                |> Html.map JoinGamePageMsg

        ContinueGamePage pageModel ->
            ContinueGame.view pageModel
                |> Html.map ContinueGamePageMsg


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

        JoinGamePage _ ->
            "Join Game"

        ContinueGamePage _ ->
            "Continue Game"



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

        ( LogoutResponse (Ok _), _ ) ->
            ( { model
                | route = Route.Home
                , session = Session.toLoggedOut model.session
              }
            , Cmd.none
            )
                |> initCurrentPage

        ( LogoutResponse (Err _), _ ) ->
            -- TODO: make some global banner to display err in??
            ( model, Cmd.none )

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

        ( JoinGamePageMsg submsg, JoinGamePage pageModel ) ->
            let
                ( updatedPageModel, updatedCmd ) =
                    JoinGame.update submsg pageModel
            in
            ( { model | page = JoinGamePage updatedPageModel }
            , Cmd.map JoinGamePageMsg updatedCmd
            )

        ( ContinueGamePageMsg submsg, ContinueGamePage pageModel ) ->
            let
                ( updatedPageModel, updatedCmd ) =
                    ContinueGame.update submsg pageModel
            in
            ( { model | page = ContinueGamePage updatedPageModel }
            , Cmd.map ContinueGamePageMsg updatedCmd
            )

        ( _, _ ) ->
            -- generic mismatch case handler
            ( model, Cmd.none )



-- INIT --


{-| Takes a nullable json obj from the ngo\_viewer\_data cookie.
-}
init : Maybe Session.UserData -> Url -> Nav.Key -> ( Model, Cmd Msg )
init maybeUserData url navKey =
    let
        session =
            Session.fromCookie maybeUserData navKey

        model =
            { page = NotFoundPage
            , route = Route.parseUrl url
            , session = session
            , navKey = navKey
            }
    in
    initCurrentPage ( model, Cmd.none )


initCurrentPage : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
initCurrentPage ( model, existingCmds ) =
    let
        loggedOutRoutes =
            case model.route of
                Route.NotFound ->
                    ( NotFoundPage, Cmd.none )

                Route.Logout ->
                    let
                        ( pageModel, pageCmds ) =
                            Home.init
                    in
                    ( HomePage pageModel
                    , doLogout LogoutResponse
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

                Route.Home ->
                    let
                        ( pageModel, pageCmds ) =
                            Home.init
                    in
                    ( HomePage pageModel
                    , Cmd.map HomePageMsg pageCmds
                    )

                _ ->
                    -- redirect to login
                    ( NotFoundPage
                    , pushUrl Route.SignIn (Session.navKey model.session)
                    )

        authOnlyRoutes userData =
            case model.route of
                Route.GameCreate ->
                    let
                        ( pageModel, pageCmds ) =
                            GameCreate.init model.navKey userData
                    in
                    ( GameCreatePage pageModel
                    , Cmd.map GameCreatePageMsg pageCmds
                    )

                Route.GamePlay gameId ->
                    let
                        ( pageModel, pageCmds ) =
                            GamePlay.init gameId
                    in
                    ( GamePlayPage pageModel
                    , Cmd.map GamePlayPageMsg pageCmds
                    )

                Route.JoinGame ->
                    let
                        ( pageModel, pageCmds ) =
                            JoinGame.init
                    in
                    ( JoinGamePage pageModel
                    , Cmd.map JoinGamePageMsg pageCmds
                    )

                Route.ContinueGame ->
                    let
                        ( pageModel, pageCmds ) =
                            ContinueGame.init
                    in
                    ( ContinueGamePage pageModel
                    , Cmd.map ContinueGamePageMsg pageCmds
                    )

                _ ->
                    loggedOutRoutes

        ( currentPage, mappedCmds ) =
            case model.session of
                Session.LoggedIn navKey userData ->
                    authOnlyRoutes userData

                Session.LoggedOut navKey ->
                    loggedOutRoutes
    in
    ( { model | page = currentPage }
    , Cmd.batch [ existingCmds, mappedCmds ]
    )



-- SUBSCRIPTIONS --


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.page of
        NotFoundPage ->
            Sub.none

        HomePage pageModel ->
            Sub.none

        GameCreatePage pageModel ->
            Sub.none

        GamePlayPage pageModel ->
            Sub.map GamePlayPageMsg (GamePlay.subscriptions pageModel)

        SignUpPage pageModel ->
            Sub.none

        SignInPage pageModel ->
            Sub.none

        JoinGamePage pageModel ->
            Sub.none

        ContinueGamePage pageModel ->
            Sub.none



-- MAIN --


main : Program (Maybe Session.UserData) Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = LinkClicked
        , onUrlChange = UrlChanged
        }
