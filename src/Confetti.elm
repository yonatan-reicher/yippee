module Confetti exposing (Model, Msg(..), init, update, view, subscriptions)

{-| HEADS UP! You can view this example alongside the running code at


We're going to make confetti come out of the party popper emoji: 🎉
([emojipedia](https://emojipedia.org/party-popper/)) Specifically, we're going
to lift our style from [Mutant Standard][ms], a wonderful alternate emoji set,
which is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike
4.0 International License.

[ms]: https://mutant.tech/

-}

import Html exposing (Html)
import Html.Attributes exposing (style)
import Particle exposing (Particle)
import Particle.System as System exposing (System)
import Random exposing (Generator)
import Random.Extra
import Random.Float exposing (normal)
import Svg exposing (Svg)
import Svg.Attributes as SAttrs



-- Generators!


{-| So, let's break down what we've got: this emoji is a cone bursting stuff
towards the upper right (you can see it at `tada.png` in the repo.) We have:

  - little brightly-colored squares. Looks like they can spin!
  - longer, wavy, brightly-colored streamers (but we'll just use rectangles here)

Let's model those as a custom type!

-}
type Confetti
    = Square
        { color : Color
        , rotations : Float

        -- we add a rotation offset to our rotations when rendering. It looks
        -- pretty odd if all the particles start or end in the same place, so
        -- this is part of our random generation.
        , rotationOffset : Float
        }
    | Streamer
        { color : Color
        , length : Int
        }
    | Heart 
        { color : (Int, Int, Int)
        , size : Float
        , rotation : Float
        }
    | PlusOne
        { color : (Int, Int, Int)
        , size : Float
        , rotation : Float
        }




type Color
    = Red
    | Pink
    | Yellow
    | Green
    | Blue


genRed : Generator (Int, Int, Int)
genRed =
    Random.map3
        (\red green blue -> (red, green, blue))
        (normal 200 40 |> Random.map round)
        (normal 60 10 |> Random.map round)
        (normal 50 10 |> Random.map round)


genGreen : Generator (Int, Int, Int)
genGreen =
    Random.map3
        (\red green blue -> (red, green, blue))
        (Random.float 100 150 |> Random.map round)
        (normal 210 40 |> Random.map round)
        (normal 50 10 |> Random.map round)


genHeart : Generator Confetti
genHeart =
    Random.map3
        (\color size rotation -> 
            Heart
                { color = color
                , size = size
                , rotation = rotation
                }
        )
        genRed
        (Random.float 1.5 2.5)
        (Random.float 0 1)


genPlusOne : Generator Confetti
genPlusOne =
    Random.map3
        (\color size rotation -> 
            PlusOne
                { color = color
                , size = size
                , rotation = rotation
                }
        )
        genGreen
        (normal 1.2 0.2)
        (normal 0 0.01)


{-| Generate a confetti square, using the color ratios seen in Mutant Standard.
-}
genSquare : Generator Confetti
genSquare =
    Random.map3
        (\color rotations rotationOffset ->
            Square
                { color = color
                , rotations = rotations
                , rotationOffset = rotationOffset
                }
        )
        (Random.weighted
            ( 1 / 5, Red )
            [ ( 1 / 5, Pink )
            , ( 1 / 5, Yellow )
            , ( 2 / 5, Green )
            ]
        )
        (normal 1 1)
        (Random.float 0 1)


{-| Generate a streamer, again using those color ratios
-}
genStreamer : Generator Confetti
genStreamer =
    Random.map2
        (\color length ->
            Streamer
                { color = color
                , length = round (abs length)
                }
        )
        (Random.uniform Pink [ Yellow, Blue ])
        (normal 25 10 |> Random.map (max 10))


{-| Generate confetti according to the ratios in Mutant Standard's tada emoji.
-}
genConfetti : Generator Confetti
genConfetti =
    Random.Extra.frequency
        ( 5 / 8, genSquare )
        [ ( 3 / 8, genStreamer ) ]


{-| We're going to emit particles at the mouse location, so we pass those
parameters in here and use them without modification.
-}
confettiAt : Float -> Float -> Generator (Particle Confetti)
confettiAt x y =
    Particle.init genConfetti
        |> Particle.withLifetime (normal 1.5 0.25)
        |> Particle.withLocation (Random.constant { x = x, y = y })
        |> Particle.withDirection (normal (degrees 0) (degrees 15))
        |> Particle.withSpeed (normal 750 150)
        |> Particle.withGravity 980
        |> Particle.withDrag
            (\confetti ->
                { density = 0.001226
                , coefficient =
                    case confetti of
                        Square _ ->
                            1.15

                        Streamer _ ->
                            0.85

                        Heart _ -> 1 -- Impossible
                        PlusOne _ -> 1 -- Impossible
                , area =
                    case confetti of
                        Square _ ->
                            1

                        Streamer { length } ->
                            toFloat length / 10

                        Heart _ -> 1 -- Impossible
                        PlusOne _ -> 1 -- Impossible
                }
            )


genHeartOrPlusOne : Generator Confetti
genHeartOrPlusOne =
    Random.Extra.frequency
        ( 0.7, genHeart )
        [ ( 0.3, genPlusOne ) ]


heartsAt : Float -> Float -> Generator (Particle Confetti)
heartsAt x y =
    Particle.init genHeartOrPlusOne
        |> Particle.withLifetime (normal 2.5 0.35)
        |> Particle.withLocation
            (Random.map2 
                (\movedX movedY -> { x = movedX, y = movedY })
                (normal x 50)
                (normal y 20)
            )
        |> Particle.withDirection (Random.constant 0)
        |> Particle.withSpeed (normal 100 50)
        |> Particle.withGravity -20


type alias Model =
    { system : System Confetti
    }


type Msg
    = TriggerConfetti Float Float
    | TriggerHearts Float Float
    | ParticleMsg (System.Msg Confetti)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TriggerConfetti x y ->
            ( { model | system = System.burst (Random.list 100 (confettiAt x y)) model.system }
            , Cmd.none
            )

        TriggerHearts x y ->
            ( { model | system = System.burst (Random.list 20 (heartsAt x y)) model.system }
            , Cmd.none
            )

        ParticleMsg particleMsg ->
            ( { model | system = System.update particleMsg model.system }
            , Cmd.none
            )



-- views


view : Model -> Html msg
view model =
    Html.main_
        []
        [ System.view viewConfetti
            [ style "width" "100%"
            , style "height" "100%"
            , style "z-index" "1"
            , style "position" "fixed"
            , style "top" "0"
            , style "right" "0"
            , style "pointer-events" "none"
            ]
            model.system
        {-
        , Html.img
            [ Attrs.src "tada.png"
            , Attrs.width 64
            , Attrs.height 64
            , Attrs.alt "\"tada\" emoji from Mutant Standard"
            , style "position" "absolute"
            , style "left" (String.fromFloat (mouseX - 20) ++ "px")
            , style "top" (String.fromFloat (mouseY - 30) ++ "px")
            , style "user-select" "none"
            , style "cursor" "none"
            , style "z-index" "0"
            ]
            []
        -}
        ]


viewConfetti : Particle Confetti -> Svg msg
viewConfetti particle =
    let
        lifetime =
            Particle.lifetimePercent particle

        -- turns out that opacity is pretty expensive for browsers to calculate,
        -- and will slow down our framerate if we change it too much. So while
        -- we *could* do this with, like, a bezier curve or something, we
        -- actually want to just keep it as stable as possible until we actually
        -- need to fade out at the end.
        opacity =
            if lifetime < 0.1 then
                lifetime * 10

            else
                1
    in
    case Particle.data particle of
        Square { color, rotationOffset, rotations } ->
            Svg.rect
                [ SAttrs.width "10px"
                , SAttrs.height "10px"
                , SAttrs.x "-5px"
                , SAttrs.y "-5px"
                , SAttrs.rx "2px"
                , SAttrs.ry "2px"
                , SAttrs.fill (fill color)
                , SAttrs.stroke "black"
                , SAttrs.strokeWidth "4px"
                , SAttrs.opacity <| String.fromFloat opacity
                , SAttrs.transform <|
                    "rotate("
                        ++ String.fromFloat ((rotations * lifetime + rotationOffset) * 360)
                        ++ ")"
                ]
                []

        Streamer { color, length } ->
            Svg.rect
                [ SAttrs.height "10px"
                , SAttrs.width <| String.fromInt length ++ "px"
                , SAttrs.y "-5px"
                , SAttrs.rx "2px"
                , SAttrs.ry "2px"
                , SAttrs.fill (fill color)
                , SAttrs.stroke "black"
                , SAttrs.strokeWidth "4px"
                , SAttrs.opacity <| String.fromFloat opacity
                , SAttrs.transform <|
                    "rotate("
                        ++ String.fromFloat (Particle.directionDegrees particle)
                        ++ ")"
                ]
                []

        Heart { color, size, rotation } -> 
            Svg.path
                [ SAttrs.d <| heartPath
                , SAttrs.fill (fillTuple color)
                , SAttrs.stroke "black"
                , SAttrs.strokeWidth "2px"
                , SAttrs.opacity <| String.fromFloat opacity
                , SAttrs.transform <|
                    "rotate("
                        ++ String.fromFloat (rotation * 360)
                        ++ ") scale("
                        ++ String.fromFloat size
                        ++ ")"
                ]
                []


        PlusOne { color, size, rotation } -> 
            Svg.text_
                [ SAttrs.x "0"
                , SAttrs.y "0"
                , SAttrs.fill (fillTuple color)
                , SAttrs.stroke (fillTuple color)
                , SAttrs.strokeWidth "2.5px"
                , SAttrs.opacity <| String.fromFloat opacity
                , SAttrs.transform <|
                    "rotate("
                        ++ String.fromFloat (rotation * 360)
                        ++ ") scale("
                        ++ String.fromFloat size
                        ++ ")"
                ]
                [ Svg.text "+1" ]


heartPath : String
heartPath =
    """
    M 1,3
    A 2,2 0,0,1 5,3
    A 2,2 0,0,1 9,3
    Q 9,6 5,9
    Q 1,6 1,3 z
    """


fill : Color -> String
fill color =
    case color of
        Red ->
            "#D72D35"

        Pink ->
            "#F2298A"

        Yellow ->
            "#F2C618"

        Green ->
            "#2ACC42"

        Blue ->
            "#37CBE8"


fillTuple : (Int, Int, Int) -> String
fillTuple (r, g, b) =
    "rgb(" ++ String.fromInt r ++ "," ++ String.fromInt g ++ "," ++ String.fromInt b ++ ")"



init : Model
init =
    { system = System.init (Random.initialSeed 0)
    }


subscriptions : Model -> Sub Msg
subscriptions model =
    System.sub [] ParticleMsg model.system
