module CssUtility exposing (..)

import Css exposing (Color, Style, Transform, all, bold, bottom, color, fixed, fontFamilies, fontSize, fontWeight, important, initial, int, left, pct, position, px, rgb, translateX, zIndex)
import Html.Styled exposing (Attribute)
import Html.Styled.Attributes exposing (css)
import Html.Styled.Events exposing (preventDefaultOn)
import Json.Decode as D
import Model exposing (Vec)


preventDrag : msg -> Attribute msg
preventDrag msg =
    preventDefaultOn "dragstart" (D.succeed ( msg, True ))


black : Color
black =
    rgb 10 10 10


dark : Color
dark =
    rgb 60 60 60


white : Color
white =
    rgb 255 255 255


gray : Color
gray =
    rgb 228 228 228


softRed : Color
softRed =
    rgb 255 178 170


centerX : Transform {}
centerX =
    translateX (pct -50)


cssUnset : List Style -> Attribute msg
cssUnset list =
    css
        [ important (all initial :: zIndex (int 999999) :: list |> Css.batch)
        ]


myFontStyle : Style
myFontStyle =
    Css.batch
        [ fontWeight bold
        , color white
        , fontSize (px 20)
        , fontFamilies
            [ "Segoe UI"
            , "Lucida Grande"
            , "Helvetica Neue"
            , "Helvetica"
            , "Arial"
            , "sans-serif"
            ]
        ]


myFontStyleDark : Style
myFontStyleDark =
    Css.batch
        [ fontWeight bold
        , color dark
        , fontSize (px 20)
        , fontFamilies
            [ "Segoe UI"
            , "Lucida Grande"
            , "Helvetica Neue"
            , "Helvetica"
            , "Arial"
            , "sans-serif"
            ]
        ]


screenPosition : Vec -> Style
screenPosition { x, y } =
    Css.batch
        [ position fixed
        , bottom (px y)
        , left (px x)
        ]
