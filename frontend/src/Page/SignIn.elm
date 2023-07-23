module Page.SignIn exposing (Model, Msg(..), init, update, view)

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
    , formResponse : WebData SigninResponseData
    , session : Session
    }


type Msg
    = SaveUsername String
    | SavePassword String
    | SendHttpSigninReq
    | ReceiveHttpSigninResp (WebData SigninResponseData)
    | UpdateSession Session


type alias SigninResponseData =
    { uid : Int
    }


type alias SigninRequestData r =
    { r
        | username : String
        , password : String
    }



-- VIEW --


view : Model -> Html Msg
view model =
    div [ class "TODO css here" ]
        [ h1 [] [ text "Sign In" ]
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
                [ text "Signin Success!" ]

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
    Html.form [ onSubmit SendHttpSigninReq ]
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
            [ button [ type_ "submit" ]
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


signinDecoder : Decode.Decoder SigninResponseData
signinDecoder =
    Decode.succeed SigninResponseData
        |> Json.Decode.Pipeline.required "uid" Decode.int


signinEncoder : SigninRequestData r -> Encode.Value
signinEncoder reqData =
    Encode.object
        [ ( "username", Encode.string reqData.username )
        , ( "password", Encode.string reqData.password )
        ]


sendSigninReq : SigninRequestData r -> Cmd Msg
sendSigninReq reqData =
    Http.post
        { url = "/api/accounts/signin"
        , body = Http.jsonBody (signinEncoder reqData)
        , expect =
            signinDecoder
                |> Http.expectJson (RemoteData.fromResult >> ReceiveHttpSigninResp)
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

        SendHttpSigninReq ->
            ( { model | formResponse = RemoteData.Loading }
            , sendSigninReq model
            )

        ReceiveHttpSigninResp (RemoteData.Success _) ->
            -- TODO: save auth state somewhere; cookie?
            ( model
            , message (UpdateSession (Session.toLoggedIn model.session))
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
