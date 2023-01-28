module Logic exposing (validMove)

import Model.Board as Board exposing (..)
import Model.Game as Game exposing (..)
import Model.Move as Move exposing (Move(..))
import Model.Piece as Piece exposing (..)
import Set exposing (..)


type alias MoveCheck =
    Piece -> Int -> Game -> ( Bool, Maybe String )


okay =
    ( True, Nothing )


{-| Determine whether a move on the board is legal.
if yes -> (True, Nothing)
if not -> (False, Just errorMessage)
-}
validMove : Move.Move -> Game -> ( Bool, Maybe String )
validMove move gameState =
    let
        applyChecks : List MoveCheck -> Piece -> Int -> Game -> ( Bool, Maybe String )
        applyChecks checks piece position game =
            case checks of
                [] ->
                    okay

                check :: checksTail ->
                    case check piece position game of
                        ( False, Just errorMessage ) ->
                            ( False, Just errorMessage )

                        _ ->
                            applyChecks checksTail piece position game
    in
    case move of
        Move.Pass ->
            okay

        Move.Play piece position ->
            applyChecks legalPlayChecks piece position gameState


legalPlayChecks : List MoveCheck
legalPlayChecks =
    [ \piece position game ->
        let
            checkMessage =
                "You can't play on top of other pieces"

            pieceAtPosition =
                Board.getPieceAt position game.board
        in
        case pieceAtPosition of
            Just Piece.None ->
                okay

            _ ->
                ( False, Just checkMessage )
    , \piece position game ->
        let
            checkMessage =
                "You can't repeat your last move"
        in
        case game.lastMove of
            Just (Move.Play _ prevPos) ->
                if position == prevPos then
                    ( False, Just checkMessage )

                else
                    okay

            _ ->
                okay
    , \piece position game ->
        let
            checkMessage =
                "You can't cause your own capture"

            seenSet : Set Int
            seenSet =
                Set.empty

            potentialGameState =
                { game | board = setPieceAt position piece game.board }
        in
        if not (isSurroundedByEnemyOrWall potentialGameState seenSet position) then
            okay

        else
            ( False, Just checkMessage )
    ]


type alias BoardData r =
    { r
        | playerColor : Piece.ColorChoice
        , board : Board.Board
        , boardSize : Board.BoardSize
    }


isSurroundedByEnemyOrWall : BoardData r -> Set Int -> Int -> Bool
isSurroundedByEnemyOrWall boardData visited position =
    let
        alreadySeen =
            Set.member position visited

        updatedVisited =
            Set.insert position visited

        piece =
            getPieceAt position boardData.board

        playerPiece =
            colorToPiece boardData.playerColor

        enemyPiece =
            colorInverse boardData.playerColor |> colorToPiece
    in
    if alreadySeen then
        -- don't count already seen pieces toward safety
        True

    else
        case piece of
            Just stonePiece ->
                if stonePiece == playerPiece then
                    -- check all neighboring spaces
                    List.all (isSurroundedByEnemyOrWall boardData updatedVisited) <|
                        [ getPositionUpFrom position boardData.boardSize
                        , getPositionDownFrom position boardData.boardSize
                        , getPositionRightFrom position
                        , getPositionLeftFrom position
                        ]

                else if stonePiece == enemyPiece then
                    True

                else
                    -- empty space; FREEDOM!!!
                    False

            Nothing ->
                -- wall
                True
