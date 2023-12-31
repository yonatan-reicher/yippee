module Yippee exposing (Msg(..), Yippee, update, view, maxHappiness)

import Css exposing (deg, num, opacity, px, rotate, scaleX, transforms, width)
import Css.Transitions exposing (easeInOut, transition)
import CssUtility exposing (..)
import Html.Styled exposing (Html, img)
import Html.Styled.Attributes exposing (src)
import Html.Styled.Events exposing (onClick)
import Model exposing (Resources, Vec)


type alias Yippee a =
    { a
        | pos : Vec
        , targetPos : Vec
        , focusPos : Vec
        , flipped : Bool
        , happiness : Float
        , level : Int
        , jump : Float
    }


type Msg
    = Clicked
    | Dragged


maxHappiness : Float
maxHappiness =
    10


lerp : Float -> Float -> Float -> Float
lerp a b t =
    a + (b - a) * (Basics.min 1 (Basics.max 0 t))


minWidth : Float
minWidth =
    80


maxWidth : Float
maxWidth =
    140


view : Resources -> Yippee a -> Html Msg
view { yippeeUrl } { pos, flipped, jump, happiness } =
    let
        xScale =
            not flipped |> boolToSign

        transformTransitionTime =
            if jump == 0 then
                200

            else
                0
    in
    img
        [ src yippeeUrl
        , preventDrag Dragged
        , onClick Clicked
        , cssUnset
            [ width <| px <| lerp minWidth maxWidth (happiness / maxHappiness)
            , screenPosition { x = pos.x, y = pos.y + 400 * (1 - (2 * jump - 1) ^ 2 |> Basics.max 0) }
            , opacity (num 0.95)
            , transition
                [ Css.Transitions.transform3 transformTransitionTime 0 easeInOut
                , Css.Transitions.width3 1000 0 easeInOut
                ]
            , transforms
                [ centerX
                , scaleX xScale
                , rotate (deg <| -jump * 360)
                ]
            , Css.property "image-rendering" "crisp-edges"
            , Css.property "filter" "brightness(1.2)"
            ]
        ]
        []


update : Msg -> Yippee a -> ( Yippee a, Cmd Msg )
update msg model =
    Debug.todo "update"


boolToSign : Bool -> Float
boolToSign b =
    if b then
        1

    else
        -1
