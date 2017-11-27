module Lia.Quiz.Types
    exposing
        ( Hints
        , Quiz(..)
        , QuizElement
        , QuizState(..)
        , QuizVector
        , Solution(..)
        )

import Array exposing (Array)
import Lia.Helper exposing (ID)
import Lia.Inline.Types exposing (Line)


type alias QuizVector =
    Array QuizElement


type alias Hints =
    List Line


type Solution
    = Open
    | Solved
    | ReSolved


type alias QuizElement =
    { solved : Solution
    , state : QuizState
    , hints : Int
    , trial : Int
    }


type QuizState
    = TextState String
    | SingleChoiceState Int
    | MultipleChoiceState (Array Bool)


type Quiz
    = Text String ID Hints
    | SingleChoice Int (List Line) ID Hints
    | MultipleChoice (Array Bool) (List Line) ID Hints
