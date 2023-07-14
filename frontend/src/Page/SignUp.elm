module Page.SignUp exposing (Model, Msg, init, update, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)


type alias Model =
    { username : String
    , password : String
    , confirmPassword : String
    , errorBannerText : Maybe String
    }


type Msg
    = Signup
    | SaveUsername String
    | SavePassword String
    | SaveConfirmPassword String



-- VIEW --


view : Model -> Html Msg
view model =
    div [ class "TODO css here" ]
        [ h1 [] [ text "Sign Up" ]
        , viewBanner model
        , viewForm model
        ]


viewBanner : Model -> Html Msg
viewBanner model =
    case model.errorBannerText of
        Nothing ->
            div [] []

        Just bannerText ->
            div [ style "color" "red" ]
                [ text <| "Error: " ++ bannerText ]


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
            [ button [ type_ "submit", onClick Signup ]
                [ text "Create Account" ]
            ]
        ]



-- UPDATE --


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

        Signup ->
            if model.password /= model.confirmPassword then
                ( { model | errorBannerText = Just "Passwords don't match!" }
                , Cmd.none
                )

            else
                -- TODO: network req
                ( { model | errorBannerText = Nothing }
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
    , errorBannerText = Nothing
    }
