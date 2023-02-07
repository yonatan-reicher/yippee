port module Ports exposing (..)

import Model exposing (State, Vec)


port frame : ({ delta : Float, time : Float } -> a) -> Sub a


port requestSave : State -> Cmd a


port saveDone : (() -> a) -> Sub a


port mouseMove : (Vec -> a) -> Sub a
