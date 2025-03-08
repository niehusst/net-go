module Page.SignIn exposing (Model, Msg(..), init, update, view)

import CmdExtra exposing (message)
import Error exposing (stringFromHttpError)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onSubmit)
import Http
import RemoteData exposing (RemoteData, WebData)
import Route exposing (Route, pushUrl)
import Session exposing (Session)
import View.Loading exposing (viewLoading)
import View.Error exposing (viewErrorBanner)
import API.Accounts exposing (sendSigninReq, AuthRequestData, AuthResponseData)


type alias Model =
    { username : String
    , password : String
    , formResponse : WebData AuthResponseData
    , session : Session
    }


type Msg
    = SaveUsername String
    | SavePassword String
    | SendHttpSigninReq
    | ReceiveHttpSigninResp (WebData AuthResponseData)
    | UpdateSession Session




-- VIEW --


view : Model -> Html Msg
view model =
    div [ class "w-full flex flex-col justify-center items-center" ]
        [ h1 [ class "text-center text-3xl font-bold my-4" ] [ text "Sign In" ]
        , viewBody model
        ]


viewBody : Model -> Html Msg
viewBody model =
    div [ class "w-full flex flex-col max-w-xs" ]
        [ case model.formResponse of
            RemoteData.NotAsked ->
                viewForm model

            RemoteData.Loading ->
                viewLoading "Loading..."

            RemoteData.Success msg ->
                -- this will likely never be shown
                text "Signin Success!"

            RemoteData.Failure error ->
                div [ class "flex flex-col justify-center items-center" ]
                    [ viewForm model
                    , viewErrorBanner <| "Error: " ++ (stringForAuthError error)
                    ]
        ]


viewForm : Model -> Html Msg
viewForm model =
    Html.form
        [ onSubmit SendHttpSigninReq
        , class "flex flex-col justify-center items-center"
        ]
        [ div [ class "my-2" ]
            [ text "Username"
            , input
                [ id "username"
                , type_ "text"
                , onInput SaveUsername
                , class "shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                ]
                []
            ]
        , div [ class "my-2" ]
            [ text "Password"
            , input
                [ id "password"
                , type_ "password"
                , onInput SavePassword
                , class "shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                ]
                []
            ]
        , div [ class "my-2" ]
            [ button [ type_ "submit", class "btn" ]
                [ text "Sign in" ]
            ]
        ]



-- UPDATE --


stringForAuthError : Http.Error -> String
stringForAuthError error =
    case error of
        Http.BadStatus _ ->
            "Failed to signin for that username and password."

        _ ->
            stringFromHttpError error



update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SaveUsername username ->
            ( { model | username = username }
            , Cmd.none
            )

        SavePassword password ->
            ( { model | password = password }
            , Cmd.none
            )

        SendHttpSigninReq ->
            ( { model | formResponse = RemoteData.Loading }
            , sendSigninReq model ReceiveHttpSigninResp
            )

        ReceiveHttpSigninResp (RemoteData.Success respData) ->
            let
                userData =
                    { id = respData.uid
                    , username = respData.username
                    }
            in
            ( model
            , message (UpdateSession (Session.toLoggedIn userData model.session ))
            )

        ReceiveHttpSigninResp response ->
            -- fallthrough catch other RemoteData states
            ( { model | formResponse = response }
            , Cmd.none
            )

        UpdateSession session ->
            ( { model | session = session }
            , pushUrl Route.Home (Session.navKey session)
            )



-- INIT --


init : Session -> ( Model, Cmd Msg )
init session =
    ( initialModel session
    , Cmd.none
    )


initialModel : Session -> Model
initialModel session =
    { username = ""
    , password = ""
    , formResponse = RemoteData.NotAsked
    , session = session
    }
