module Model exposing (Apple, Flags, Model, Resources, State, Vec, Yippee, encodeApple, encodeState, encodeVec, initialState, stateDecoder, vecDecoder)

import Confetti
import Json.Encode as E
import Json.Decode as D


type alias Flags =
    { maybeState : Maybe (State {})
    , resources : Resources
    , windowSize : Vec
    , url : String
    }


type alias Model =
    State
        { resources : Resources
        , windowSize : Vec
        , confetti : Confetti.Model
        , sounds : List String
        , url: String
        , fullscreen : Bool
        , enabled : Bool
        }


type alias State a =
    Yippee
        { a
            | mousePos : Vec
            , apples : List Apple
        }


type alias Yippee a =
    { a
        | pos : Vec
        , targetPos : Vec
        , focusPos : Vec
        , flipped : Bool
        , happiness : Float
        , jump : Float
    }


type alias Apple =
    { pos : Vec
    , velocity : Float
    , roll : Float -- The amount of radians to roll per second.
    , rotation : Float
    }


type alias Resources =
    { yippeeUrl : String
    , appleUrl : String
    , yippeeSoundUrl : String
    }


type alias Vec =
    { x : Float, y : Float }


encodeState : State a -> E.Value
encodeState { pos, targetPos, flipped, apples, mousePos, focusPos, happiness, jump } =
    E.object
        [ ( "pos", encodeVec pos )
        , ( "targetPos", encodeVec targetPos )
        , ( "focusPos", encodeVec focusPos )
        , ( "mousePos", encodeVec mousePos )
        , ( "flipped", E.bool flipped )
        , ( "apples", E.list encodeApple apples )
        , ( "happiness", E.float happiness )
        , ( "jump", E.float jump )
        ]


encodeApple : Apple -> E.Value
encodeApple { pos, roll, rotation, velocity } =
    E.object
        [ ( "pos", encodeVec pos )
        , ( "velocity", E.float velocity )
        , ( "roll", E.float roll )
        , ( "rotation", E.float rotation )
        ]


encodeVec : Vec -> E.Value
encodeVec { x, y } =
    E.object [ ( "x", E.float x ), ( "y", E.float y ) ]


initialState : State {}
initialState =
    { pos = { x = 0, y = 0 }
    , targetPos = { x = 200, y = 0 }
    , focusPos = { x = 200, y = 0 }
    , mousePos = { x = 200, y = 0 }
    , happiness = 0
    , flipped = True
    , apples = []
    , jump = 0
    }

stateDecoder : D.Decoder (State {})
stateDecoder =
    D.map8 (\pos targetPos focusPos mousePos flipped apples happiness jump ->
        { pos = pos
        , targetPos = targetPos
        , focusPos = focusPos
        , mousePos = mousePos
        , flipped = flipped
        , apples = apples
        , happiness = happiness
        , jump = jump
        })
        (D.field "pos" vecDecoder)
        (D.field "targetPos" vecDecoder)
        (D.field "focusPos" vecDecoder)
        (D.field "mousePos" vecDecoder)
        (D.field "flipped" D.bool)
        (D.field "apples" (D.list appleDecoder))
        (D.field "happiness" D.float)
        (D.field "jump" D.float)


appleDecoder : D.Decoder Apple
appleDecoder =
    D.map4 Apple
        (D.field "pos" vecDecoder)
        (D.field "velocity" D.float)
        (D.field "roll" D.float)
        (D.field "rotation" D.float)


vecDecoder : D.Decoder Vec
vecDecoder =
    D.map2 Vec (D.field "x" D.float) (D.field "y" D.float)
