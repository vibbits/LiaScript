module Lia.Inline.Parser
    exposing
        ( combine
        , comment
        , comment_string
        , comments
        , inlines
        , line
        , newline
        , newlines
        , stringTill
        , whitelines
        )

import Combine exposing (..)
import Combine.Char exposing (..)
import Lia.Effect.Parser as Effect
import Lia.Inline.Types exposing (..)
import Lia.PState exposing (PState)


comment : Parser s a -> Parser s (List a)
comment p =
    lazy <|
        \() ->
            (string "<!--" *> manyTill p (string "-->")) <?> "HTML comment"


comment_string : Parser s String
comment_string =
    anyChar
        |> comment
        |> map (String.fromList >> String.trim)


comments : Parser s ()
comments =
    skip (many (comment anyChar))


html : Parser s Inline
html =
    html_void <|> html_block


html_void : Parser s Inline
html_void =
    lazy <|
        \() ->
            HTML
                <$> choice
                        [ regex "<area[^>\\n]*>"
                        , regex "<base[^>\\n]*>"
                        , regex "<br[^>\\n]*>"
                        , regex "<col[^>\\n]*>"
                        , regex "<embed[^>\\n]*>"
                        , regex "<hr[^>\\n]*>"
                        , regex "<img[^>\\n]*>"
                        , regex "<input[^>\\n]*>"
                        , regex "<keygen[^>\\n]*>"
                        , regex "<link[^>\\n]*>"
                        , regex "<menuitem[^>\\n]*>"
                        , regex "<meta[^>\\n]*>"
                        , regex "<param[^>\\n]*>"
                        , regex "<source[^>\\n]*>"
                        , regex "<track[^>\\n]*>"
                        , regex "<wbr[^>\\n]*>"
                        ]


html_block : Parser s Inline
html_block =
    let
        p tag =
            (\c ->
                String.append ("<" ++ tag) c
                    ++ "</"
                    ++ tag
                    ++ ">"
            )
                <$> stringTill (string "</" *> string tag <* string ">")
    in
    HTML <$> (whitespace *> string "<" *> regex "[a-zA-Z0-9]+" >>= p)


combine : Inlines -> Inlines
combine list =
    case list of
        [] ->
            []

        [ xs ] ->
            [ xs ]

        x1 :: x2 :: xs ->
            case ( x1, x2 ) of
                ( Chars str1, Chars str2 ) ->
                    combine (Chars (str1 ++ str2) :: xs)

                _ ->
                    x1 :: combine (x2 :: xs)


line : Parser PState Inlines
line =
    (\list -> combine <| List.append list [ Chars " " ]) <$> many1 inlines


newline : Parser s ()
newline =
    (char '\n' <|> eol) |> skip


newlines : Parser s ()
newlines =
    many newline |> skip


whitelines : Parser s ()
whitelines =
    regex "[ \\t\\n]*" |> skip


inlines : Parser PState Inline
inlines =
    lazy <|
        \() ->
            comments
                *> choice
                    [ html
                    , code
                    , reference
                    , formula
                    , Effect.inline inlines
                    , strings
                    ]


stringTill : Parser s p -> Parser s String
stringTill p =
    String.fromList <$> manyTill anyChar p


formula : Parser s Inline
formula =
    let
        p1 =
            Formula False <$> (string "$" *> regex "[^\\n$]+" <* string "$")

        p2 =
            Formula True <$> (string "$$" *> stringTill (string "$$"))
    in
    choice [ p2, p1 ]


url_full : Parser s String
url_full =
    regex "[a-zA-Z]+://(/)?[a-zA-Z0-9\\.\\-\\_]+\\.([a-z\\.]{2,6})[^ \\)\\t\\n]*"


url_mail : Parser s String
url_mail =
    maybe (string "mailto:") *> regex "[a-zA-Z0-9_.\\-]+@[a-zA-Z0-9_.\\-]+"


url : Parser s Url
url =
    lazy <|
        \() ->
            choice
                [ Mail <$> url_mail
                , Full <$> url_full
                ]


inline_url : Parser s Reference
inline_url =
    (\u -> Link u (Full u)) <$> (url_full <|> url_mail)


reference : Parser s Inline
reference =
    lazy <|
        \() ->
            let
                info =
                    brackets (regex "[^\\]\n]*")

                style =
                    maybe (String.fromList <$> comment anyChar)

                url_ =
                    parens (url <|> (Partial <$> regex "[^\\)\n]*"))

                link =
                    Link <$> info <*> url_

                image =
                    Image <$> (string "!" *> info) <*> url_ <*> style

                movie =
                    Movie <$> (string "!!" *> info) <*> url_ <*> style
            in
            Ref <$> choice [ movie, image, link ]


arrows : Parser s Inline
arrows =
    lazy <|
        \() ->
            choice
                [ string "<-->" $> Symbol "&#10231;" --"⟷"
                , string "<--" $> Symbol "&#10229;" --"⟵"
                , string "-->" $> Symbol "&#10230;" --"⟶"
                , string "<<-" $> Symbol "&#8606;" --"↞"
                , string "->>" $> Symbol "&#8608;" --"↠"
                , string "<->" $> Symbol "&#8596;" --"↔"
                , string ">->" $> Symbol "&#8611;" --"↣"
                , string "<-<" $> Symbol "&#8610;" --"↢"
                , string "->" $> Symbol "&#8594;" --"→"
                , string "<-" $> Symbol "&#8592;" --"←"
                , string "<~" $> Symbol "&#8604;" --"↜"
                , string "~>" $> Symbol "&#8605;" --"↝"
                , string "<==>" $> Symbol "&#10234;" --"⟺"
                , string "==>" $> Symbol "&#10233;" --"⟹"
                , string "<==" $> Symbol "&#10232;" --"⟸"
                , string "<=>" $> Symbol "&#8660;" --"⇔"
                , string "=>" $> Symbol "&#8658;" --"⇒"
                , string "<=" $> Symbol "&#8656;" --"⇐"
                ]


smileys : Parser s Inline
smileys =
    lazy <|
        \() ->
            choice
                [ string ":-)" $> Symbol "&#x1f600;" --"🙂"
                , string ";-)" $> Symbol "&#x1f609;" --"😉"
                , string ":-D" $> Symbol "&#x1f600;" --"😀"
                , string ":-O" $> Symbol "&#128558;" --"😮"
                , string ":-(" $> Symbol "&#128542;" --"🙁"
                , string ":-|" $> Symbol "&#128528;" --"😐"
                , string ":-/" $> Symbol "&#128533;" --"😕"
                , string ":-P" $> Symbol "&#128539;" --"😛"
                , string ";-P" $> Symbol "&#128540;" --"😜"
                , string ":-*" $> Symbol "&#128535;" --"😗"
                , string ":')" $> Symbol "&#128514;" --"😂"
                , string ":'(" $> Symbol "&#128554;" --"😢"😪
                ]
                <?> "smiley"


between_ : String -> Parser PState Inline
between_ str =
    lazy <|
        \() ->
            choice
                [ string str *> inlines <* string str
                , Container <$> (string str *> manyTill inlines (string str))
                ]


strings : Parser PState Inline
strings =
    lazy <|
        \() ->
            let
                base =
                    Chars <$> regex "[^#*_~:;`!\\^\\[|{}\\\\\\n\\-<>=$ ]+" <?> "base string"

                escape =
                    Chars <$> (string "\\" *> regex "[\\^#*_~`\\\\${}\\[\\]|]") <?> "escape string"

                italic =
                    Italic <$> (between_ "*" <|> between_ "_") <?> "italic string"

                bold =
                    Bold <$> (between_ "**" <|> between_ "__") <?> "bold string"

                strike =
                    Strike <$> between_ "~" <?> "striked out string"

                underline =
                    Underline <$> between_ "~~" <?> "underlined string"

                superscript =
                    Superscript <$> between_ "^" <?> "superscript string"

                characters =
                    Chars <$> regex "[~:_;\\-<>=${} ]"

                base2 =
                    Chars <$> regex "[^#\\n|*]+" <?> "base string"
            in
            choice
                [ Ref <$> inline_url
                , base
                , html
                , arrows
                , smileys
                , escape
                , bold
                , italic
                , underline
                , strike
                , superscript
                , characters
                , base2
                ]


code : Parser s Inline
code =
    Verbatim <$> (string "`" *> regex "[^`\\n]+" <* string "`") <?> "inline code"
