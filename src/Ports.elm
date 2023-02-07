port module Ports exposing (frame, mouseMove, requestSave, saveDone)

import Json.Encode as E
import Model exposing (State, Vec, encodeState)


port frame : ({ delta : Float, time : Float } -> a) -> Sub a


requestSave : State a -> Cmd msg
requestSave =
    requestSave1 << encodeState


port requestSave1 : E.Value -> Cmd msg


port saveDone : (() -> a) -> Sub a


port mouseMove : (Vec -> a) -> Sub a
