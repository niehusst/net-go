module Page.SignUp exposing (Model, Msg(..), init, update, view)

import CmdExtra exposing (message)
import Error exposing (stringFromHttpError)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onSubmit)
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline
import Json.Encode as Encode
import RemoteData exposing (RemoteData, WebData)
import Route exposing (Route, pushUrl)
import Session exposing (Session)


type alias Model =
    { username : String
    , password : String
    , confirmPassword : String
    , formResponse : WebData SignupResponseData
    , session : Session
    }


type Msg
    = SaveUsername String
    | SavePassword String
    | SaveConfirmPassword String
    | SendHttpSignupReq
    | ReceiveHttpSignupResp (WebData SignupResponseData)
    | UpdateSession Session


type alias SignupResponseData =
    { ok : Bool
    }


type alias SignupRequestData r =
    { r
        | username : String
        , password : String
    }



-- VIEW --


view : Model -> Html Msg
view model =
    div [ class "TODO css here" ]
        [ h1 [] [ text "Sign Up" ]
        , viewBody model
        ]


viewBody : Model -> Html Msg
viewBody model =
    case model.formResponse of
        RemoteData.NotAsked ->
            div []
                [ viewForm model ]

        RemoteData.Loading ->
            -- TODO: spinner or something + css
            div []
                [ text "Loading..." ]

        RemoteData.Success msg ->
            -- this will likely never be shown
            div []
                [ text "Signup Success!" ]

        RemoteData.Failure error ->
            div []
                [ viewForm model
                , viewBanner error
                ]


viewBanner : Http.Error -> Html Msg
viewBanner error =
    -- TODO: replace with header banner shared code (Page.elm)
    let
        errString =
            stringForAuthError error
    in
    div [ style "color" "red" ]
        [ text <| "Error: " ++ errString ]


viewForm : Model -> Html Msg
viewForm model =
    Html.form [ onSubmit SendHttpSignupReq ]
        [ div []
            [ text "Username"
            , input
                [ id "username"
                , type_ "text"
                , onInput SaveUsername
                ]
                []
            ]
        , div []
            [ text "Password"
            , input
                [ id "password"
                , type_ "password"
                , onInput SavePassword
                ]
                []
            ]
        , div []
            [ text "Confirm Password"
            , input
                [ id "confirmpassword"
                , type_ "password"
                , onInput SaveConfirmPassword
                ]
                []
            ]
        , div []
            [ button [ type_ "submit" ]
                [ text "Create Account" ]
            ]
        ]



-- UPDATE --


stringForAuthError : Http.Error -> String
stringForAuthError error =
    case error of
        Http.BadStatus errCode ->
            if errCode == 400 then
                "Failed to signup for that username and password. Note: passwords must be between 8 and 30 characters."

            else
                stringFromHttpError error

        _ ->
            stringFromHttpError error


signupDecoder : Decode.Decoder SignupResponseData
signupDecoder =
    Decode.succeed SignupResponseData
        |> Json.Decode.Pipeline.required "ok" Decode.bool


signupEncoder : SignupRequestData r -> Encode.Value
signupEncoder reqData =
    Encode.object
        [ ( "username", Encode.string reqData.username )
        , ( "password", Encode.string reqData.password )
        ]


sendSignupReq : SignupRequestData r -> Cmd Msg
sendSignupReq reqData =
    Http.post
        { url = "/api/accounts/signup"
        , body = Http.jsonBody (signupEncoder reqData)
        , expect =
            signupDecoder
                |> Http.expectJson (RemoteData.fromResult >> ReceiveHttpSignupResp)
        }


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
                ( { model | formResponse = RemoteData.Failure (Http.BadBody "Passwords don't match!") }
                , Cmd.none
                )

            else
                ( { model | formResponse = RemoteData.Loading }
                , sendSignupReq model
                )

        ReceiveHttpSignupResp (RemoteData.Success _) ->
            -- TODO: save auth state somewhere; cookie?
            ( model
            , message (UpdateSession (Session.toLoggedIn model.session))
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
    , session = session
    }
