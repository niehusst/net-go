module Page.SignIn exposing (Model, Msg, init, update, view)

import Error exposing (stringFromHttpError)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline
import Json.Encode as Encode
import RemoteData exposing (RemoteData, WebData)
import Sha256 exposing (sha256)


type alias Model =
    { username : String
    , password : String
    , formResponse : WebData SigninResponseData
    }


type Msg
    = SaveUsername String
    | SavePassword String
    | SendHttpSigninReq
    | ReceiveHttpSigninResp (WebData SigninResponseData)


type alias SigninResponseData =
    { ok : Bool
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
    let
        errString =
            stringForAuthError error
    in
    div [ style "color" "red" ]
        [ text <| "Error: " ++ errString ]


viewForm : Model -> Html Msg
viewForm model =
    Html.form []
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
            [ button [ type_ "submit", onClick SendHttpSigninReq ]
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


signinDecoder : Decode.Decoder SigninResponseData
signinDecoder =
    Decode.succeed SigninResponseData
        |> Json.Decode.Pipeline.required "ok" Decode.bool


signinEncoder : SigninRequestData r -> Encode.Value
signinEncoder reqData =
    Encode.object
        [ ( "username", Encode.string reqData.username )
        , ( "password", Encode.string reqData.password )
        ]


sendSigninReq : SigninRequestData r -> Cmd Msg
sendSigninReq reqData =
    let
        hashedReqData =
            { reqData | password = sha256 reqData.password }
    in
    Http.post
        { url = "/api/signin"
        , body = Http.jsonBody (signinEncoder hashedReqData)
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

        --        ReceiveHttpSigninResp (RemoteData.Success _) ->
        --            -- TODO: save auth state somewhere
        --            -- TODO: nav to home page or somethign
        --            ( model
        --            , Cmd.none
        --            )
        ReceiveHttpSigninResp response ->
            -- fallthrough catch other RemoteData states
            ( { model | formResponse = response }
            , Cmd.none
            )



-- INIT --


init : ( Model, Cmd Msg )
init =
    ( initialModel
    , Cmd.none
    )


initialModel : Model
initialModel =
    { username = ""
    , password = ""
    , formResponse = RemoteData.NotAsked
    }
