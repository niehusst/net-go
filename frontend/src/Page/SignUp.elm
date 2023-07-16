module Page.SignUp exposing (Model, Msg, init, update, view)

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
    , confirmPassword : String
    , formResponse : WebData SignupResponseData
    }


type Msg
    = SaveUsername String
    | SavePassword String
    | SaveConfirmPassword String
    | SendHttpSignupReq
    | ReceiveHttpSignupResp (WebData SignupResponseData)


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
    let
        errString =
            stringFromHttpError error
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
            [ text "Confirm Password"
            , input
                [ id "confirmpassword"
                , type_ "password"
                , onInput SaveConfirmPassword
                ]
                []
            ]
        , div []
            [ button [ type_ "submit", onClick SendHttpSignupReq ]
                [ text "Create Account" ]
            ]
        ]



-- UPDATE --


stringFromHttpError : Http.Error -> String
stringFromHttpError error =
    case error of
        Http.BadUrl msg ->
            msg

        Http.Timeout ->
            "Server took too long to repond; try again later"

        Http.NetworkError ->
            "Network error; try again later"

        Http.BadStatus errCode ->
            if errCode == 500 then
                "Internal server error :("

            else
                "Failed to signup for that username and password. Note: passwords must be between 8 and 30 characters."

        Http.BadBody msg ->
            msg


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
    let
        hashedReqData =
            { reqData | password = sha256 reqData.password }
    in
    Http.post
        { url = "/api/signup"
        , body = Http.jsonBody (signupEncoder hashedReqData)
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

        --        ReceiveHttpSignupResp (RemoteData.Success _) ->
        --            -- TODO: save auth state somewhere
        --            -- TODO: nav to home page or somethign
        --            ( model
        --            , Cmd.none
        --            )
        ReceiveHttpSignupResp response ->
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
    , confirmPassword = ""
    , formResponse = RemoteData.NotAsked
    }
