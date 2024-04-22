module Page.GameCreate exposing (Model, FormData, Msg(..), init, update, view)

import API.Games exposing (createGame, CreateGameResponse)
import Browser.Navigation as Nav
import Error
import Html exposing (..)
import Html.Attributes exposing (href, value, selected, type_, step, min)
import Html.Events exposing (onClick, onInput)
import Http
import CmdExtra exposing (message)
import Model.Game as Game exposing (Game)
import Model.Board as Board exposing (BoardSize(..), boardSizeToString, boardSizeToInt, intToBoardSize)
import Model.ColorChoice exposing (ColorChoice(..), colorToString, stringToColor)
import Model.Score as Score
import Route exposing (Route, pushUrl)
import RemoteData

type Msg
    = StoreBoardSize String
    | StoreColorChoice String
    | StoreKomi String
    | CreateGame -- http req msgs for creating game in db
    | GameCreated (Result Http.Error CreateGameResponse)


type alias Model =
    { formData : FormData
    , navKey : Nav.Key
    , httpError : Maybe Http.Error
    }


type alias FormData =
    { boardSize : BoardSize
    , colorChoice : ColorChoice
    , komi : Float
    }

setSize : BoardSize -> FormData -> FormData
setSize size data =
    { data | boardSize = size }

setColor : ColorChoice -> FormData -> FormData
setColor color data =
    { data | colorChoice = color }

setKomi : Float -> FormData -> FormData
setKomi komi data =
    { data | komi = komi }

formDataToGame : FormData -> Game
formDataToGame formData =
    { boardSize = formData.boardSize
    , board = Board.emptyBoard formData.boardSize
    , lastMoveWhite = Nothing
    , lastMoveBlack = Nothing
    , history = []
    , playerColor = formData.colorChoice
    , isOver = False
    , score = Score.initWithKomi formData.komi
    }


-- VIEW --


view : Model -> Html Msg
view model =
    div []
        [ h2 [] [ text "Game Settings" ]
        , viewGameSettings model.formData
        , Error.viewHttpError model.httpError
        ]


viewGameSettings : FormData -> Html Msg
viewGameSettings data =
    let
        black = colorToString Black

        white = colorToString White

        full = boardSizeToString Full

        med = boardSizeToString Medium

        small = boardSizeToString Small
    in
    div []
        [ Html.form []
              [ div []
                    [ label [] [ text "Color" ]
                    , select [ onInput StoreColorChoice ]
                        [ option
                              [ value black
                              , selected (data.colorChoice == Black)
                              ]
                              [ text black ]
                        , option
                              [ value white
                              , selected (data.colorChoice == White)
                              ]
                              [ text white ]
                        ]
                    ]
              , div []
                    [ label [] [ text "Board size" ]
                    , select [ onInput StoreBoardSize ]
                        -- TODO: flexibility
                             [ option [ value (String.fromInt <| boardSizeToInt Full)
                                      , selected (data.boardSize == Full)
                                      ]
                                      [ text full ]
                             , option [ value (String.fromInt <| boardSizeToInt Medium)
                                      , selected (data.boardSize == Medium)
                                      ]
                                      [ text med ]
                             , option [ value (String.fromInt <| boardSizeToInt Small)
                                      , selected (data.boardSize == Small)
                                      ]
                                      [ text small ]
                             ]
                    ]
              , div []
                    [ label [] [ text "Komi" ]
                    , input [ onInput StoreKomi
                            , type_ "number"
                            , step "0.1"
                            , Html.Attributes.min "0"
                            , value (String.fromFloat data.komi)
                            ]
                            []
                    ]
              , button [ onClick CreateGame ]
                       [ text "Create game" ]
              ]
        ]



-- UPDATE --


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StoreKomi komiStr ->
            let
                value = String.toFloat komiStr
            in
            case value of
                Just komi ->
                    ( { model | formData = setKomi komi model.formData }
                    , Cmd.none
                    )
                Nothing ->
                    ( model
                    , Cmd.none
                    )

        StoreBoardSize sizeStr ->
            let
                value = String.toInt sizeStr
            in
            case value of
                Just candidateSizeInt ->
                    let
                        candidateSize = intToBoardSize candidateSizeInt
                    in
                    case candidateSize of
                        Just boardSize ->
                            ( { model | formData = setSize boardSize model.formData }
                            , Cmd.none
                            )
                        Nothing ->
                            ( model
                            , Cmd.none
                            )
                Nothing ->
                    ( model
                    , Cmd.none
                    )

        StoreColorChoice colorStr ->
            case stringToColor colorStr of
                Just colorChoice ->
                    ( { model | formData = setColor colorChoice model.formData }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        CreateGame ->
            ( { model | httpError = Nothing }
            , createGame (formDataToGame model.formData) (GameCreated)
            )

        GameCreated (Ok createdResponse) ->
            ( model
            , pushUrl (Route.GamePlay createdResponse.uid) model.navKey
            )

        GameCreated (Err httpErr) ->
            ( { model | httpError = Just httpErr }
            , Cmd.none
            )


-- INIT --


init : Nav.Key -> ( Model, Cmd Msg )
init navKey =
    ( initialModel navKey
    , Cmd.none
    )


initialModel : Nav.Key -> Model
initialModel navKey =
    { formData = { boardSize = Full
                 , colorChoice = Black
                 , komi = 5.5 -- current? Japanese regulation komi
                 }
    , navKey = navKey
    , httpError = Nothing
    }
