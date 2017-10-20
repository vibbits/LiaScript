module Lia.Utils exposing (evaluateJS, evaluateJS2, formula, get_local, highlight, load_js, set_local, stringToHtml)

--this is where we import the native module
--import Array

import Html exposing (Html)
import Html.Attributes as Attr
import Json.Encode
import Native.Utils
import Task exposing (attempt)


highlight : String -> String -> Html msg
highlight language code =
    stringToHtml <| Native.Utils.highlight language code


formula : Bool -> String -> Html msg
formula displayMode string =
    stringToHtml <| Native.Utils.formula displayMode string


evaluateJS : String -> Result String String
evaluateJS code =
    Native.Utils.evaluate code


load_js : String -> Result String String
load_js url =
    Native.Utils.load_js url


evaluateJS2 : (Result err ok -> msg) -> Int -> String -> Cmd msg
evaluateJS2 resultToMessage idx code =
    attempt resultToMessage (Native.Utils.evaluate2 idx code)


stringToHtml : String -> Html msg
stringToHtml str =
    Html.span [ Attr.property "innerHTML" (Json.Encode.string str) ] []


get_local : String -> Maybe String
get_local key =
    Native.Utils.get_local key


set_local : String -> String -> Bool
set_local key value =
    Native.Utils.set_local key value
