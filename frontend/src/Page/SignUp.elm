module Page.SignUp exposing (Model, Msg, init, update, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)


type alias Model =
    { username : String
    , password : String
    }


type Msg
    = Signup
    | SaveUsername String
    | SavePassword String



-- VIEW --


view : Model -> Html Msg
view model =
    div [ class "TODO css here" ]
        [ h1 [] [ text "Sign Up" ]
        , Html.form []
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
                [ button [ type_ "submit", onClick Signup ]
                    [ text "Create Account" ]
                ]
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

        Signup ->
            -- TODO: network req
            ( model
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
    }
