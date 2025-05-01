module Page.SignUp exposing (Model, Msg(..), init, update, view)

import API.Accounts exposing (AuthRequestData, AuthResponseData, sendSignupReq)
import CmdExtra exposing (message)
import Error exposing (CustomWebData, HttpErrorResponse, stringFromHttpError)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onSubmit)
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline
import Json.Encode as Encode
import RemoteData exposing (RemoteData)
import Route exposing (Route, pushUrl)
import Session exposing (Session)
import View.Error exposing (viewErrorBanner)
import View.Loading exposing (viewLoading)


type alias Model =
    { username : String
    , password : String
    , confirmPassword : String
    , formResponse : CustomWebData AuthResponseData
    , clientError : Maybe String
    , session : Session
    }


type Msg
    = SaveUsername String
    | SavePassword String
    | SaveConfirmPassword String
    | SendHttpSignupReq
    | ReceiveHttpSignupResp (CustomWebData AuthResponseData)
    | UpdateSession Session



-- VIEW --


view : Model -> Html Msg
view model =
    div [ class "w-full flex flex-col justify-center items-center" ]
        [ h1 [ class "text-center text-3xl font-bold my-4" ] [ text "Sign Up" ]
        , viewBody model
        ]


viewError : Maybe String -> Html Msg
viewError maybeErrText =
    case maybeErrText of
        Just errText ->
            viewErrorBanner <| "ERROR: " ++ errText

        Nothing ->
            text ""


viewBody : Model -> Html Msg
viewBody model =
    div [ class "w-full max-w-xs flex flex-col" ]
        [ case model.formResponse of
            RemoteData.NotAsked ->
                div []
                    [ viewForm model
                    , viewError model.clientError
                    ]

            RemoteData.Loading ->
                viewLoading "Loading..."

            RemoteData.Success msg ->
                -- this will likely never be shown
                text "Signup Success!"

            RemoteData.Failure error ->
                div []
                    [ viewForm model
                    , viewErrorBanner <| stringForAuthError error
                    ]
        ]


viewForm : Model -> Html Msg
viewForm model =
    Html.form
        [ onSubmit SendHttpSignupReq
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
            [ text "Confirm Password"
            , input
                [ id "confirmpassword"
                , type_ "password"
                , onInput SaveConfirmPassword
                , class "shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                ]
                []
            ]
        , div [ class "my-2" ]
            [ button [ type_ "submit", class "btn" ]
                [ text "Create Account" ]
            ]
        ]



-- UPDATE --


stringForAuthError : HttpErrorResponse -> String
stringForAuthError error =
    case error.httpError of
        Http.BadStatus _ ->
            "Failed to signup for that username and password. Note: passwords must be between 8 and 30 characters."

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

        SaveConfirmPassword password ->
            ( { model | confirmPassword = password }
            , Cmd.none
            )

        SendHttpSignupReq ->
            if model.password /= model.confirmPassword then
                ( { model | clientError = Just "Passwords don't match!" }
                , Cmd.none
                )

            else
                ( { model
                    | formResponse = RemoteData.Loading
                    , clientError = Nothing
                  }
                , sendSignupReq model ReceiveHttpSignupResp
                )

        ReceiveHttpSignupResp (RemoteData.Success respData) ->
            let
                userData =
                    { id = respData.uid
                    , username = respData.username
                    }
            in
            ( model
            , message (UpdateSession (Session.toLoggedIn userData model.session))
            )

        ReceiveHttpSignupResp response ->
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
    , confirmPassword = ""
    , formResponse = RemoteData.NotAsked
    , clientError = Nothing
    , session = session
    }
